import LiveDemo from './LiveDemo';

const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080';

export default function Page() {
  return (
    <main className="page">
      <section className="hero">
        <div className="eyebrow">Fictional platform demo</div>
        <h1>Reliable production software needs reliable platform engineering.</h1>
        <p>
          VisionCast demonstrates license validation, content entitlements, CDN delivery,
          multi-environment infrastructure, observability, and deployment automation —
          the same platform concerns that keep a live production event running even when
          the cloud has a bad day.
        </p>
        <div className="actions">
          <a href={`${apiBase}/healthz`} target="_blank" rel="noreferrer">API Health</a>
          <a href={`${apiBase}/metrics`} target="_blank" rel="noreferrer">Prometheus Metrics</a>
          <a href="http://localhost:3001" target="_blank" rel="noreferrer">Grafana</a>
          <a href="http://localhost:9090" target="_blank" rel="noreferrer">Prometheus UI</a>
        </div>
      </section>

      <section className="grid">
        <article>
          <h2>License Validation</h2>
          <p>Local production apps validate subscriptions against resilient regional APIs. Invalid licenses return business responses — not errors — to keep SLOs accurate.</p>
        </article>
        <article>
          <h2>Content Entitlements</h2>
          <p>Subscription tiers gate access to 50k+ media assets. Entitled items are returned with short-lived signed CloudFront URLs so content never leaks across plan boundaries.</p>
        </article>
        <article>
          <h2>Multi-Region Resilience</h2>
          <p>Each API response includes the serving region. CloudFront distributes the static site globally. ECS Fargate can be deployed to additional regions behind Route 53 latency routing.</p>
        </article>
        <article>
          <h2>Infrastructure as Code</h2>
          <p>Terraform modules compose VPC, ECS Fargate, RDS, ElastiCache, and CloudFront. Three isolated environment stacks — dev, staging, prod — from the same modules.</p>
        </article>
        <article>
          <h2>CI/CD Pipelines</h2>
          <p>GitHub Actions builds, tests, and publishes Docker images, then runs Terraform plan/apply with OIDC-based AWS credentials. Branch-to-environment promotion with required approvals on prod.</p>
        </article>
        <article>
          <h2>Observability</h2>
          <p>Prometheus metrics on every route with p95 latency and validation outcome counters. Grafana dashboard, SLO definitions, and incident runbooks ship with the repo.</p>
        </article>
      </section>

      <LiveDemo />
    </main>
  );
}
