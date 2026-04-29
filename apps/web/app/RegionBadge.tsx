'use client';
import { useState, useEffect } from 'react';

const API = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080';

export default function RegionBadge() {
  const [region, setRegion] = useState<string | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    fetch(`${API}/healthz`, { cache: 'no-store' })
      .then((r) => r.json())
      .then((d) => {
        setRegion(d.region ?? null);
        setReady(d.status === 'ok');
      })
      .catch(() => {
        setRegion(null);
        setReady(false);
      });
  }, []);

  return (
    <div className="region-badge">
      <span className="region-dot" style={{ background: ready ? '#22c55e' : '#555' }} />
      <span>API: <strong>{region ?? '…'}</strong></span>
      <span className="region-sep">·</span>
      <span>CDN: <strong>CloudFront Global</strong></span>
    </div>
  );
}
