# Interview Demo Script

## Pre-interview setup (do this first)

```bash
docker compose up --build
```

Open in browser: http://localhost:3000

Tabs to have ready:
- http://localhost:3000 (web + live demo)
- http://localhost:8080/metrics (Prometheus text)
- http://localhost:9090 (Prometheus UI)
- http://localhost:3001 (Grafana — user: admin / admin)

---

## 1. Opening (30 seconds)

> "I built a fictional production-platform demo around a desktop presentation app. The platform challenge is that a local app running at a live event — church, concert, sports venue — still depends on cloud services for licensing, subscriptions, and media content. Any cloud outage during a service is a real problem for their customers, so I focused on resilience, observable deployments, and repeatable infrastructure."

---

## 2. Architecture walkthrough (~2 min)

Open `README.md` — point to the Mermaid diagram.

Key points to hit:
- Static website on S3 + CloudFront (distributed CDN — not a single origin)
- Go API on ECS Fargate behind ALB — scales horizontally, no pets
- PostgreSQL (RDS) for license state, Redis (ElastiCache) as a low-latency cache layer
- S3 + CloudFront for creative content with signed URLs
- GitHub Actions → OIDC → AWS (no long-lived credentials)
- Three isolated environment stacks from the same Terraform modules: dev / staging / prod

---

## 3. Live web demo (~2 min)

Open http://localhost:3000

Point out the six capability cards. Then scroll to the **Live API Demo** section.

Click each "Run" button and narrate:

**Run #1 — Valid license:**
> "This is what a ProPresenter install does at startup — validates the key and gets back the plan and feature flags. The response includes which region served it — useful for debugging multi-region latency."

**Run #2 — Expired license:**
> "Notice this is HTTP 200 with `valid: false`, not a 403 or 5xx. Expired licenses are an expected business outcome, not a platform failure. If I counted them as errors my SLO error budget would burn on normal user behavior."

**Run #3 — Content entitlements:**
> "The license tier gates access. Pro subscribers get the full content library. Each item comes back with a signed URL and a 900-second TTL — CloudFront verifies the signature so the CDN enforces the subscription boundary, not just the API."

**Run #4 — Health probes:**
> "Two separate probes: `/healthz` is always fast — just confirms the process is alive. `/readyz` checks the database — ECS and Fly.io use this to decide whether to route traffic. If the DB is down the service goes out of rotation without a deploy."

---

## 4. API deep dive — terminal (~2 min)

Show the Go API source: `apps/api/internal/handlers/handlers.go`

Key talking points:
- Clean handler separation (handlers / models / db / metrics / config)
- Region is read from `AWS_REGION` or `FLY_REGION` env var — same binary deploys to AWS ECS and Fly.io
- `writeJSON` helper keeps HTTP status and encoding consistent across all routes
- No panic recovery needed — Go HTTP server isolates request goroutines

```bash
# Direct curl examples if you want to show raw terminal output:
curl -X POST http://localhost:8080/api/v1/license/validate \
  -H "Content-Type: application/json" \
  -d '{"license_key":"RV-DEMO-1234","device_id":"foh-imac","app":"presenter","version":"7.18.0"}'

curl "http://localhost:8080/api/v1/content/entitlements?license_key=RV-DEMO-1234"
```

---

## 5. Observability (~1.5 min)

```bash
curl http://localhost:8080/metrics | grep license_validation
```

Open Grafana at http://localhost:3001 — import `ops/dashboards/grafana-dashboard.json`.

> "Three panels: valid license rate, p95 latency by route, and request rate. I'd layer in SLO burn-rate alerts on top of these in production — the runbook at `ops/runbooks/slo-license-validation.md` defines the objectives and alert thresholds."

---

## 6. Infrastructure (~2 min)

Open `infra/terraform/modules/ecs-api/main.tf`

Key points:
- One module, three environments — dev/staging/prod differ only in CPU/memory sizing, AZ count, log retention, and desired task count
- `prod` runs 3 AZs, `dev` runs 2
- ECS desired count is `2` in prod, `1` elsewhere — Fargate spreads tasks across AZs automatically
- `scan_on_push = true` on ECR — container scanning is infrastructure, not an afterthought

Open `infra/terraform/environments/prod/variables.tf` — show the wider CIDR allocation (separate `/16` per environment, no overlap risk).

---

## 7. CI/CD (~1.5 min)

Open `.github/workflows/api-deploy.yml`

Key points:
- Branch-to-environment mapping: `develop` → dev, `staging` → staging, `main` → prod
- OIDC authentication — no AWS access keys stored in GitHub
- Plan is uploaded as an artifact and applied in a separate job — plan what you apply, apply what you planned
- Terraform init uses per-environment S3 backend key — isolated state per environment
- `prod` environment requires approval in GitHub (set in GitHub UI)

---

## 8. Fly.io (~30 seconds)

Open `fly.toml`

> "The job mentioned Fly.io specifically. The same Go binary that runs on ECS Fargate also deploys to Fly.io — it reads `FLY_REGION` for the region field, so multi-region Fly deployments surface the right region in API responses. Auto-stop-machines keeps costs low for dev/staging."

---

## Closing

> "The specific services here aren't the point — I'd adapt them to your actual stack. What I was demonstrating is the pattern: observable, repeatable, environment-isolated deployments where infrastructure changes go through the same review process as application code."
