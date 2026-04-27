const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080';

export default function Page() {
  return (
    <main className="page">
      <section className="hero">
        <div className="eyebrow">Fictional platform demo</div>
        <h1>Reliable production software needs reliable platform engineering.</h1>
        <p>
          VisionCast demonstrates license validation, content entitlements, CDN delivery,
          multi-environment infrastructure, observability, and deployment automation.
        </p>
        <div className="actions">
          <a href={`${apiBase}/healthz`}>API Health</a>
          <a href={`${apiBase}/metrics`}>Prometheus Metrics</a>
        </div>
      </section>

      <section className="grid">
        <article>
          <h2>License Validation</h2>
          <p>Local production apps can validate subscriptions and activate devices against resilient regional APIs.</p>
        </article>
        <article>
          <h2>Content Entitlements</h2>
          <p>Subscription tiers unlock creative content served through signed CDN URLs with short-lived access.</p>
        </article>
        <article>
          <h2>Platform Operations</h2>
          <p>Terraform, GitHub Actions, metrics, runbooks, and SLOs keep the system repeatable and observable.</p>
        </article>
      </section>
    </main>
  );
}
