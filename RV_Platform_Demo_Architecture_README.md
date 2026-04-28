# 🌍 RV Platform Demo – Resilient Multi-Region Architecture

This project demonstrates a **production-ready, globally distributed platform architecture** inspired by Renewed Vision’s ecosystem: ProPresenter-style desktop software, ProContent-style media delivery, account services, licensing, activation, and subscription-based entitlement APIs.

The goal is to showcase **DevOps, SRE, and cloud architecture best practices** with a focus on:

- 🌐 Low latency worldwide
- 🔁 Multi-region resilience
- 📦 Containerized deployments
- ⚡ CDN-first delivery
- 🔐 Secure licensing and content access
- 📊 Observability and reliability
- 🧰 Infrastructure as Code
- 🚀 GitHub Actions-based CI/CD

---

## 🧱 Architecture Overview

```text
Users / Desktop App / Browser
        |
        v
Route 53 + CloudFront + AWS WAF
        |
        +--> Static Website / Docs / Frontend Assets
        |       |
        |       v
        |   S3 Private Origin
        |
        +--> Media / ProContent Downloads
        |       |
        |       v
        |   S3 Media Origin + CloudFront Signed URLs
        |
        +--> Dynamic API Traffic
                |
                v
        AWS Global Accelerator
                |
                v
        Regional ALBs
                |
                v
        ECS Fargate / Containerized Services
                |
        +-------+-------------+-------------+
        |                     |             |
   License API           Account API    Content API
        |                     |             |
        v                     v             v
Regional Redis        Cognito/Auth     Content Metadata
        |
        v
Aurora Global Database
```

---

## 🚀 Key Design Principles

### 1. CDN-First Architecture

All static and media assets should be served through **Amazon CloudFront**.

Examples:

- Marketing website
- Documentation
- Application update assets
- JavaScript/CSS/image bundles
- ProContent-style media previews
- Thumbnails
- Licensed media downloads

Benefits:

- Low latency for users around the world
- Reduced load on application servers
- Better cache hit ratio for repeat assets
- Global TLS termination
- DDoS absorption at the edge
- WAF protection before traffic reaches the application layer

Important design principle:

> Large media files should not flow through application containers. The API should authorize access, then CloudFront should serve the file from the nearest edge location.

---

## 2. Stateless Multi-Region APIs

Dynamic application services should run as stateless containers in multiple AWS regions.

Example regions:

```text
us-east-1
us-west-2
eu-west-1
ap-southeast-2
```

Each region contains:

- ECS Fargate services
- Application Load Balancer
- Regional Redis cache
- CloudWatch logs and metrics
- Health checks
- Autoscaling policies

Traffic is routed globally through:

```text
AWS Global Accelerator
    -> closest healthy regional ALB
    -> ECS/Fargate service
```

This allows API traffic to enter the AWS network close to the user and route to the nearest healthy service region.

---

## 3. Regional Redis Strategy

Each AWS region has its own Redis instance.

Example:

```text
us-east-1 Redis
us-west-2 Redis
eu-west-1 Redis
ap-southeast-2 Redis
```

Important:

- Redis is **not globally shared**
- Users are **not guaranteed to always hit the same region**
- Traffic may shift because of latency routing, health failover, network changes, or mobile network behavior

Design rule:

> Redis is a regional performance cache, not a source of truth.

This means Redis should be used for:

- Short-lived entitlement lookups
- License validation cache
- Content metadata cache
- Rate limiting counters
- Temporary API performance optimization

Redis should not be used as the authoritative record for:

- Billing state
- Seat ownership
- Device activation truth
- Subscription state
- Permanent session data
- License ownership

---

## 4. Cache-Aside Pattern

The safest multi-region Redis pattern is cache-aside.

```text
Request arrives in nearest region
        |
        v
Check regional Redis
        |
        +--> Cache HIT
        |       |
        |       v
        |   Return fast response
        |
        +--> Cache MISS
                |
                v
        Read from database
                |
                v
        Populate regional Redis
                |
                v
        Return response
```

This ensures:

- The system still works if Redis is empty
- A user can switch regions without breaking
- Regional cache misses are normal and expected
- The database remains the source of truth

Interview explanation:

> I would not rely on Redis for correctness across regions. I would treat Redis as a regional performance layer and design for cache misses as a normal condition.

---

## 5. Licensing and Entitlement Strategy

For a ProPresenter-style desktop app, licensing should be resilient and should not hard-fail during temporary network issues.

Possible licensing flow:

```text
Desktop App
    |
    v
License API
    |
    v
Validate account, subscription, seats, and device activation
    |
    v
Return signed entitlement token
```

Example entitlement token payload:

```json
{
  "account_id": "acct_123",
  "device_id": "device_macbook_prod_booth_01",
  "plan": "pro",
  "features": ["cloud_sync", "procontent", "bibles"],
  "expires_in": "10m",
  "offline_grace_period": "7d"
}
```

Benefits:

- Reduces repeated API calls
- Allows fast local validation
- Works across regions
- Helps the desktop app tolerate temporary connectivity problems
- Reduces Redis dependency for every request
- Supports an offline grace period for real production environments

Important design principle:

> Production software should degrade gracefully. A temporary licensing API issue should not immediately block a live event.

---

## 6. License Validation API

Example endpoints:

```http
POST /v1/devices/register
POST /v1/licenses/validate
POST /v1/licenses/refresh
GET  /v1/accounts/me/entitlements
```

The API should check:

- Account status
- Subscription status
- Seat count
- Device activation state
- License expiration
- Feature entitlements
- Fraud/revocation flags

Suggested behavior:

- Cache positive entitlement responses for 5–15 minutes
- Use short TTLs for sensitive revocation or fraud checks
- Support signed entitlement tokens
- Support offline grace periods
- Log validation attempts for audit and support

---

## 7. Content Delivery / ProContent-Style Media

The content platform should be separated into two lanes:

### Metadata API

Used for:

- Search
- Browse
- Categories
- Entitlements
- Content previews
- Asset metadata
- Download authorization

### Media Delivery

Used for:

- Large media files
- Thumbnails
- Previews
- Motion backgrounds
- Production graphics

Media delivery flow:

```text
Desktop App
    |
    v
Content API checks entitlement
    |
    v
API returns signed CloudFront URL
    |
    v
Client downloads content from nearest CloudFront edge
```

Key principle:

> App servers authorize media access, but CloudFront delivers the media.

This keeps containers focused on business logic and prevents large downloads from consuming application compute.

---

## 8. Database Design

Recommended database:

```text
Aurora PostgreSQL Global Database
```

Suggested layout:

```text
Primary writer: us-east-1
Read replicas: us-west-2, eu-west-1, ap-southeast-2
```

Use strong consistency for:

- Billing state
- Subscriptions
- Seats
- Device activations
- Account ownership
- License revocations

Use eventual consistency for:

- Content catalog
- Media metadata
- Usage analytics
- Download events
- Search indexing
- Recommendation or discovery data

Suggested supporting services:

- RDS Proxy for connection pooling
- Automated backups
- Point-in-time recovery
- Cross-region read replicas
- Alarms for replication lag

---

## 9. Multi-Region Resilience

Recommended starting model:

```text
Active-active reads
Active-passive writes
```

Why:

- License seats and device activations are consistency-sensitive
- Full active-active writes can create duplicate activations or billing conflicts
- Active-passive writes reduce complexity and protect correctness
- Read-heavy paths can still be globally fast

Example:

```text
Read traffic:
    served from nearest healthy region

Write traffic:
    routed to primary writer region

Failover:
    secondary region promoted if primary region fails
```

Interview explanation:

> I would avoid premature active-active writes for licensing because double activation and seat-count consistency matter. I would start with active-active reads and controlled writes, then move low-risk services to active-active over time.

---

## 10. Low Latency Strategy

### Static and Media Content

Use:

- CloudFront
- S3 private origins
- Origin Access Control
- Long cache TTLs for immutable assets
- Versioned asset paths
- Signed URLs for protected downloads

### API Traffic

Use:

- AWS Global Accelerator
- Regional ALBs
- ECS Fargate services
- Regional autoscaling
- Health checks

### Database Access

Use:

- Local read replicas
- Aurora Global Database
- RDS Proxy
- Async event processing for non-critical writes

### Caching

Use:

- Regional Redis
- Cache-aside pattern
- Short TTLs for license state
- Longer TTLs for content metadata
- Event-driven cache invalidation for revocations

---

## 11. Important Regional Redis Question

### Will a user always hit the same region?

No.

A user is not guaranteed to always hit the same region. Routing can change due to:

- Health failover
- Latency changes
- Network path changes
- Mobile network changes
- DNS behavior
- CloudFront or Global Accelerator routing decisions

Therefore, the architecture must assume:

```text
Request 1 -> us-east-1
Request 2 -> us-west-2
Request 3 -> eu-west-1
```

This is why Redis must be treated as a cache, not a source of truth.

Best answer:

> Because routing can shift between regions at any time, I design Redis as a cache, not a session store. For anything critical like licensing, I use signed tokens and a durable backend so the system remains correct even if every request hits a different region.

---

## 12. Failure Scenarios

### Region Failure

```text
Region becomes unhealthy
    |
    v
Global Accelerator stops routing to that endpoint
    |
    v
Traffic shifts to another healthy region
```

### Redis Failure

```text
Regional Redis unavailable
    |
    v
API treats it as cache miss
    |
    v
Read from database
    |
    v
Continue serving requests
```

### License API Failure

```text
License API unreachable
    |
    v
Desktop app uses previously issued entitlement token
    |
    v
Offline grace period protects live production
```

### Content API Failure

```text
Content API unavailable
    |
    v
Previously fetched catalog remains cached
    |
    v
Existing signed media URLs continue working until expiration
```

### S3 Origin Issue

```text
S3 origin problem
    |
    v
CloudFront continues serving cached assets where possible
    |
    v
Origin failover can route to replicated bucket
```

---

## 13. Security Considerations

Recommended security controls:

- AWS WAF at CloudFront
- Shield Standard by default
- CloudFront signed URLs or signed cookies
- Origin Access Control for S3
- IAM least privilege
- GitHub OIDC for AWS authentication
- No long-lived AWS keys in GitHub secrets
- Secrets stored in AWS Secrets Manager or SSM Parameter Store
- TLS everywhere
- JWT or signed entitlement tokens
- Rate limiting for activation endpoints
- Audit logs for license validations and device registrations

---

## 14. Containerized Deployment

Recommended platform:

```text
ECS Fargate
```

Why ECS Fargate:

- Lower operational overhead than Kubernetes
- Strong AWS-native integration
- Good fit for small platform teams
- Easy autoscaling
- Works well with ALB, CloudWatch, IAM, and ECR

Container flow:

```text
GitHub Actions
    |
    v
Build Docker image
    |
    v
Push to ECR
    |
    v
Deploy ECS service
    |
    v
Run smoke tests
```

Deployment strategy:

- Rolling deploys for lower-risk services
- Blue/green deploys for high-impact services
- Health check gates
- Automatic rollback on failed health checks
- Immutable image tags
- Separate dev, staging, and prod environments

---

## 15. CI/CD Strategy

Using GitHub Actions:

```text
Pull Request
    |
    v
Lint + Test + Build + Terraform Plan
    |
    v
Merge to develop -> Deploy dev
Merge to staging -> Deploy staging
Merge to main -> Deploy production with approval
```

Recommended workflow features:

- Separate workflows per app
- GitHub Environments for dev/staging/prod
- Required approval for production
- GitHub OIDC to AWS
- Terraform remote state in S3
- DynamoDB state locking
- Docker image promotion instead of rebuilds
- Smoke tests after deployment
- Rollback workflow

Interview explanation:

> I separate app deployment from infrastructure deployment, but keep both visible in GitHub Actions. Application changes should be fast, while infrastructure changes should be reviewed with a Terraform plan.

---

## 16. Terraform State Strategy

Recommended backend:

```text
S3 remote backend
DynamoDB lock table
Separate state path per environment
```

Example state paths:

```text
rv-platform-demo/web/dev/terraform.tfstate
rv-platform-demo/web/staging/terraform.tfstate
rv-platform-demo/web/prod/terraform.tfstate

rv-platform-demo/api/dev/terraform.tfstate
rv-platform-demo/api/staging/terraform.tfstate
rv-platform-demo/api/prod/terraform.tfstate
```

Why:

- Shared remote state for team usage
- State locking prevents concurrent modification
- Environment isolation reduces blast radius
- Separate app states reduce coupling

---

## 17. Observability

Recommended tooling:

- CloudWatch metrics and logs
- CloudWatch Container Insights
- OpenTelemetry
- X-Ray or distributed tracing
- Prometheus and Grafana if using an OSS observability stack
- CloudFront access logs
- ALB logs
- Synthetic canaries

Golden signals:

- Latency
- Traffic
- Errors
- Saturation

Important dashboards:

- License validation p95 latency
- Activation success rate
- Subscription entitlement errors
- Content API latency
- Content download 4xx/5xx
- CloudFront cache hit ratio
- Redis cache hit ratio
- Regional health
- Database replication lag
- Queue depth
- Deployment success/failure rate

---

## 18. SLO Examples

| Service | Target |
|---|---|
| License API | 99.95% uptime |
| License API Latency | p95 under 250ms |
| Content API | 99.9% uptime |
| Content API Latency | p95 under 400ms |
| Media Delivery | 99.99% availability |
| Deployment Rollback | under 10 minutes |
| Cache Hit Ratio | monitored by region |

Example SLO statement:

> License validation should be available 99.95% of the time with p95 latency under 250ms, because failed or slow validation can directly impact production readiness.

---

## 19. Interview Talk Track

Short version:

> This architecture ensures low latency by pushing static and media content to CloudFront, routing dynamic API traffic through Global Accelerator to the nearest healthy region, running stateless containers in multiple AWS regions, using regional Redis for performance, and keeping correctness in Aurora Global Database with signed entitlement tokens.

Stronger version:

> For a company like Renewed Vision, reliability is not just uptime. It is protecting the live production moment. If a church, school, or venue is minutes from going live, licensing, login, and content delivery need to degrade gracefully instead of becoming a hard blocker.

Regional Redis explanation:

> Users are not guaranteed to stay in one region, so Redis cannot be treated as shared state. I would use regional Redis only as a cache. If a request lands in a different region, a cache miss simply falls back to the durable data store and repopulates the local cache.

Content delivery explanation:

> I would not route media downloads through app containers. The API should validate entitlement and issue signed CloudFront URLs. That lets the CDN handle the heavy traffic globally while the app layer stays focused on authorization and metadata.

Licensing explanation:

> Licensing needs to be both secure and forgiving. I would use short-lived signed entitlement tokens and an offline grace period so a temporary API issue does not stop someone from running a live production.

---

## 20. Key Takeaways

- Use CloudFront for website, static assets, and media delivery
- Use AWS Global Accelerator for low-latency API routing
- Run stateless API containers in multiple regions
- Use regional Redis only as a performance cache
- Do not depend on region affinity
- Use Aurora Global Database for durable global reads and controlled writes
- Protect licensed content with signed CloudFront URLs
- Support offline grace periods for desktop app licensing
- Use GitHub Actions, Terraform, Docker, and OIDC for secure deployments
- Build observability around production-impacting user journeys

---

## Final Thought

This system is designed to protect the **live production moment**.

For a production software company, the most important reliability question is not just:

> Is the system up?

It is:

> Can the customer still run their show, service, conference, stream, or production when something goes wrong?

This architecture is built around that answer.
