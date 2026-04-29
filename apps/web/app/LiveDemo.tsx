'use client';
import { useState, useEffect } from 'react';

// Empty string means "same origin" — site and API share one CloudFront domain.
// Set NEXT_PUBLIC_API_BASE_URL=http://localhost:8080 for local development.
const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL ?? '';

type DemoCase = {
  label: string;
  tag: string;
  description: string;
  fetch: () => Promise<Response>;
};

const DEMOS: DemoCase[] = [
  {
    label: 'Valid license — active Pro subscription',
    tag: 'POST /api/v1/license/validate',
    description:
      'A ProPresenter install checks in at startup. License is active, plan returned with feature list and serving region.',
    fetch: () =>
      fetch(`${API_BASE}/api/v1/license/validate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          license_key: 'RV-DEMO-1234',
          device_id: 'foh-macbook-pro',
          app: 'presenter',
          version: '7.18.0',
        }),
      }),
  },
  {
    label: 'Expired license — graceful business response',
    tag: 'POST /api/v1/license/validate',
    description:
      'An expired key returns valid=false with a reason code. HTTP 200 keeps SLO error budgets accurate — this is a business result, not an error.',
    fetch: () =>
      fetch(`${API_BASE}/api/v1/license/validate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          license_key: 'RV-EXPIRED-0000',
          device_id: 'backstage-imac',
          app: 'presenter',
          version: '7.18.0',
        }),
      }),
  },
  {
    label: 'Content entitlements — signed CDN URLs',
    tag: 'GET /api/v1/content/entitlements',
    description:
      'Subscription tier verified against the database, then ProContent assets are returned with short-lived signed CloudFront URLs.',
    fetch: () =>
      fetch(`${API_BASE}/api/v1/content/entitlements?license_key=RV-DEMO-1234`),
  },
  {
    label: 'Health + readiness probes',
    tag: 'GET /healthz  ·  GET /readyz',
    description:
      'Liveness probe is always fast. Readiness probe checks the RDS connection — used by ECS health checks and the load balancer target group.',
    fetch: async () => {
      const [hz, rz] = await Promise.all([
        fetch(`${API_BASE}/healthz`),
        fetch(`${API_BASE}/readyz`),
      ]);
      const hzBody = await hz.json();
      const rzBody = await rz.json();
      return new Response(
        JSON.stringify({ healthz: hzBody, readyz: rzBody }, null, 2),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      );
    },
  },
];

type CardState = { status: 'idle' | 'loading' | 'done' | 'error'; json: string };

export default function LiveDemo() {
  const [states, setStates] = useState<CardState[]>(
    DEMOS.map(() => ({ status: 'idle', json: '' })),
  );
  // Resolve the displayed URL at runtime so it shows the real CloudFront domain
  // when API_BASE is empty (same-origin mode).
  const [displayUrl, setDisplayUrl] = useState(API_BASE || '…');
  useEffect(() => {
    if (!API_BASE) setDisplayUrl(window.location.origin);
  }, []);

  async function run(index: number) {
    setStates((prev) =>
      prev.map((s, i) => (i === index ? { status: 'loading', json: '' } : s)),
    );
    try {
      const res = await DEMOS[index].fetch();
      const text = await res.text();
      let pretty = text;
      try { pretty = JSON.stringify(JSON.parse(text), null, 2); } catch {}
      setStates((prev) =>
        prev.map((s, i) => (i === index ? { status: 'done', json: pretty } : s)),
      );
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setStates((prev) =>
        prev.map((s, i) =>
          i === index
            ? { status: 'error', json: `Connection failed: ${msg}\n\nCheck that the API is reachable at:\n${displayUrl}` }
            : s,
        ),
      );
    }
  }

  return (
    <section id="demo" className="demo-section">
      <div className="demo-inner">
        <div className="demo-header">
          <p className="section-label">Platform API Explorer</p>
          <h2 className="section-title">Live requests against the production stack</h2>
          <p className="section-sub">
            The APIs that power license validation and content entitlements for
            ProPresenter and ProContent — running on ECS Fargate with RDS
            PostgreSQL and ElastiCache Redis.
          </p>
          <div className="demo-api-url">
            <span className="demo-api-label">API</span>
            <code style={{ background: 'none', padding: 0, color: 'inherit' }}>{displayUrl}</code>
          </div>
        </div>

        <div className="demo-cards">
          {DEMOS.map((demo, i) => {
            const s = states[i];
            return (
              <div key={i} className="demo-card">
                <div className="demo-card-header">
                  <span className="demo-tag">{demo.tag}</span>
                  <h3>{demo.label}</h3>
                  <p>{demo.description}</p>
                </div>
                <button
                  className={`demo-run${s.status === 'loading' ? ' loading' : ''}`}
                  onClick={() => run(i)}
                  disabled={s.status === 'loading'}
                >
                  {s.status === 'loading' ? 'Running…' : 'Run'}
                </button>
                {s.status !== 'idle' && s.status !== 'loading' && (
                  <pre className={`demo-output ${s.status}`}>{s.json}</pre>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
