# Interview Demo Script

## 1. Opening

"I built a fictional production-platform demo around a desktop presentation app. The interesting platform challenge is that a local app used in live production still depends on cloud services for licensing, subscriptions, and creative content. I focused on reliability, safe deployments, observability, and repeatable infrastructure."

## 2. Show the architecture

Open the README and point to the Mermaid diagram.

Key points:

- Static web on S3 + CloudFront
- API on ECS Fargate behind ALB
- Postgres for licensing state
- Redis for low-latency cache path
- S3/CloudFront for content delivery
- GitHub Actions with OIDC to AWS

## 3. Run the local stack

```bash
docker compose up --build
```

## 4. Validate license

```bash
curl -X POST http://localhost:8080/api/v1/license/validate \
  -H "Content-Type: application/json" \
  -d '{"license_key":"RV-DEMO-1234","device_id":"foh-imac","app":"presenter","version":"7.18.0"}'
```

Say:

"I treat invalid or expired licenses as business responses, not platform errors. That keeps SLOs focused on system reliability instead of expected user behavior."

## 5. Show content entitlements

```bash
curl "http://localhost:8080/api/v1/content/entitlements?license_key=RV-DEMO-1234"
```

Say:

"In production these would be signed URLs with short TTLs, served through CloudFront."

## 6. Show observability

```bash
curl http://localhost:8080/metrics
```

Open `ops/dashboards/grafana-dashboard.json` and SLO runbook.

## 7. Show deployment maturity

Open `.github/workflows/deploy.yml` and Terraform environment folder.

Say:

"The important thing is not that this is the exact architecture. It is that the deployment path is repeatable, auditable, rollback-friendly, and observable."
