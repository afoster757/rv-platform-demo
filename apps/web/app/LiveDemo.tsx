'use client';
import { useState } from 'react';

type DemoCase = {
  label: string;
  tag: string;
  description: string;
  fetch: () => Promise<Response>;
};

const API = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080';

const DEMOS: DemoCase[] = [
  {
    label: 'Valid license — active Pro subscription',
    tag: 'POST /api/v1/license/validate',
    description: 'A ProPresenter install checks in at startup. License is active, plan returned with feature list.',
    fetch: () =>
      fetch(`${API}/api/v1/license/validate`, {
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
    description: 'An expired key returns valid=false with a reason. This is a business response, not a 4xx — keeps SLO error budgets accurate.',
    fetch: () =>
      fetch(`${API}/api/v1/license/validate`, {
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
    description: 'Subscription tier is verified, then content items are returned with short-lived signed URLs for CloudFront delivery.',
    fetch: () =>
      fetch(`${API}/api/v1/content/entitlements?license_key=RV-DEMO-1234`),
  },
  {
    label: 'Health + readiness probes',
    tag: 'GET /healthz  GET /readyz',
    description: 'Liveness probe is always fast. Readiness probe checks the database connection — used by ECS and Fly.io health checks.',
    fetch: async () => {
      const [hz, rz] = await Promise.all([
        fetch(`${API}/healthz`),
        fetch(`${API}/readyz`),
      ]);
      const hzBody = await hz.json();
      const rzBody = await rz.json();
      return new Response(JSON.stringify({ healthz: hzBody, readyz: rzBody }, null, 2), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    },
  },
];

type CardState = { status: 'idle' | 'loading' | 'done' | 'error'; json: string };

export default function LiveDemo() {
  const [states, setStates] = useState<CardState[]>(
    DEMOS.map(() => ({ status: 'idle', json: '' }))
  );

  async function run(index: number) {
    setStates((prev) =>
      prev.map((s, i) => (i === index ? { status: 'loading', json: '' } : s))
    );
    try {
      const res = await DEMOS[index].fetch();
      const text = await res.text();
      let pretty = text;
      try { pretty = JSON.stringify(JSON.parse(text), null, 2); } catch {}
      setStates((prev) =>
        prev.map((s, i) => (i === index ? { status: 'done', json: pretty } : s))
      );
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setStates((prev) =>
        prev.map((s, i) =>
          i === index ? { status: 'error', json: `Connection failed: ${msg}\n\nMake sure the local stack is running:\n  docker compose up --build` } : s
        )
      );
    }
  }

  return (
    <section className="live-demo">
      <div className="live-demo-header">
        <div className="eyebrow">Live API Demo</div>
        <h2>Run requests against the local stack</h2>
        <p>Each button calls the running API at <code>{API}</code>. Start the stack with <code>docker compose up --build</code>.</p>
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
                className={`demo-run ${s.status === 'loading' ? 'loading' : ''}`}
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
    </section>
  );
}
