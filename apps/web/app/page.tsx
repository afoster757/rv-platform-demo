import LiveDemo from './LiveDemo';
import RegionBadge from './RegionBadge';

const CLIENTS = [
  'NASA', 'The White House', 'Walmart', 'Delta', 'Chick-fil-A', 'Fox Sports',
  'NASCAR', 'NFL', 'Bethel', 'Elevation Church', 'Lakewood', 'Passion',
  'Canon', 'Purdue', 'ASU', 'SBC', 'Entertainment Tonight', 'GCPS',
  'NASA', 'The White House', 'Walmart', 'Delta', 'Chick-fil-A', 'Fox Sports',
  'NASCAR', 'NFL', 'Bethel', 'Elevation Church', 'Lakewood', 'Passion',
  'Canon', 'Purdue', 'ASU', 'SBC', 'Entertainment Tonight', 'GCPS',
];

export default function Page() {
  return (
    <>
      {/* ── NAV ─────────────────────────────────────────────── */}
      <nav className="nav">
        <a href="/" className="nav-logo">Renewed<span>Vision</span></a>
        <ul className="nav-links">
          <li><a href="#products">Products</a></li>
          <li><a href="#industries">Learn</a></li>
          <li><a href="#demo">Support</a></li>
          <li><a href="#demo">Account</a></li>
        </ul>
        <div className="nav-actions">
          <a href="#demo" className="nav-btn nav-btn-ghost">Subscribe</a>
          <a href="#demo" className="nav-btn nav-btn-solid">Download</a>
        </div>
      </nav>

      {/* ── HERO ────────────────────────────────────────────── */}
      <section className="hero">
        <div className="hero-badge">
          <span className="hero-badge-dot" />
          Platform demo — production stack
        </div>
        <h1>
          Video Presentation Software<br />
          to <span className="highlight">Tell Your Story</span>
        </h1>
        <p className="hero-sub">
          Renewed Vision builds the tools that power live production for
          worship, broadcast, sports, and enterprise — trusted by NASA,
          The White House, and thousands of live events worldwide.
        </p>
        <div className="hero-ctas">
          <a href="#products" className="btn-primary">Explore Products</a>
          <a href="#demo" className="btn-ghost">View API Demo ↓</a>
        </div>
        <div className="hero-stats">
          <div>
            <div className="hero-stat-value">50,000+</div>
            <div className="hero-stat-label">Media assets in ProContent</div>
          </div>
          <div>
            <div className="hero-stat-value">180+</div>
            <div className="hero-stat-label">Countries using ProPresenter</div>
          </div>
          <div>
            <div className="hero-stat-value">99.9%</div>
            <div className="hero-stat-label">Platform uptime SLO</div>
          </div>
        </div>
      </section>

      {/* ── CLIENTS MARQUEE ─────────────────────────────────── */}
      <div className="clients-section">
        <p className="clients-label">Trusted by the world's leading organizations</p>
        <div className="marquee-wrap">
          <div className="marquee-track">
            {CLIENTS.map((name, i) => (
              <span key={i} className="marquee-item">{name}</span>
            ))}
          </div>
        </div>
      </div>

      {/* ── PRODUCTS ────────────────────────────────────────── */}
      <section id="products" className="section">
        <p className="section-label">Our products</p>
        <h2 className="section-title">Software to power any experience</h2>
        <p className="section-sub">
          Four purpose-built applications — from live presentation to media
          management, multi-screen playback, and digital scoreboards.
        </p>
        <div className="products-grid">
          <div className="product-card">
            <div className="product-icon icon-pp">🎬</div>
            <h3>ProPresenter</h3>
            <p>The industry standard in presentation software with intuitive features and stunning visuals for live production environments.</p>
            <a href="#demo" className="product-link link-pp">Learn more →</a>
          </div>
          <div className="product-card">
            <div className="product-icon icon-pc">🎨</div>
            <h3>ProContent</h3>
            <p>Unlimited access to over 50,000 stunning visuals and assets — backgrounds, motion graphics, countdowns, and worship media.</p>
            <a href="#demo" className="product-link link-pc">Learn more →</a>
          </div>
          <div className="product-card">
            <div className="product-icon icon-pvp">▶️</div>
            <h3>ProVideoPlayer</h3>
            <p>Play back and manipulate video across one or more screens with frame-accurate control and real-time playlist management.</p>
            <a href="#demo" className="product-link link-pvp">Learn more →</a>
          </div>
          <div className="product-card">
            <div className="product-icon icon-sb">🏆</div>
            <h3>Scoreboard</h3>
            <p>The digital scoreboard solution designed for effortless operation at any venue — from high school gyms to professional arenas.</p>
            <a href="#demo" className="product-link link-sb">Learn more →</a>
          </div>
        </div>
      </section>

      {/* ── INDUSTRIES ──────────────────────────────────────── */}
      <section id="industries" className="section" style={{ paddingTop: 0 }}>
        <p className="section-label">Industries</p>
        <h2 className="section-title">Built for every venue</h2>
        <p className="section-sub">
          Purpose-built workflows for the environments where live production
          cannot fail.
        </p>
        <div className="industries-grid">
          <div className="industry-card">
            <div className="industry-icon">⛪</div>
            <h3>Worship</h3>
            <p>Lyrics, scripture, countdowns, and media cues — synchronized across every screen in the room, operated by one person.</p>
          </div>
          <div className="industry-card">
            <div className="industry-icon">🎥</div>
            <h3>Live Production</h3>
            <p>Broadcast-grade graphics and video playback for large-scale live events, conferences, and touring productions.</p>
          </div>
          <div className="industry-card">
            <div className="industry-icon">📡</div>
            <h3>Broadcast</h3>
            <p>Frame-accurate playout, lower thirds, and full-screen graphics integrated into broadcast workflows for TV and streaming.</p>
          </div>
          <div className="industry-card">
            <div className="industry-icon">🏟️</div>
            <h3>Live Sports</h3>
            <p>Real-time scoreboards, replay cues, and sponsor graphics for arenas, stadiums, and motorsport venues worldwide.</p>
          </div>
          <div className="industry-card">
            <div className="industry-icon">🎓</div>
            <h3>Education</h3>
            <p>Lecture halls, auditoriums, and campus-wide digital signage — all managed from a single intuitive interface.</p>
          </div>
          <div className="industry-card">
            <div className="industry-icon">🏛️</div>
            <h3>Government</h3>
            <p>Secure, reliable presentation infrastructure for government institutions including NASA and The White House.</p>
          </div>
        </div>
      </section>

      {/* ── CORE VALUES ─────────────────────────────────────── */}
      <div className="values-section">
        <div className="values-inner">
          <p className="section-label">Why Renewed Vision</p>
          <h2 className="section-title">The standard for live production software</h2>
          <div className="values-grid">
            <div className="value-card">
              <div className="value-number">01</div>
              <h3>Ease of use</h3>
              <p>Operators learn ProPresenter in minutes. Complex production cues become repeatable one-click workflows that any volunteer can run.</p>
            </div>
            <div className="value-card">
              <div className="value-number">02</div>
              <h3>World-class support</h3>
              <p>Live production doesn't stop for tickets. Our support team responds in real time during events — because downtime is not an option.</p>
            </div>
            <div className="value-card">
              <div className="value-number">03</div>
              <h3>Controlled quality</h3>
              <p>Every release goes through production-parity testing. The platform that runs at The White House must meet the same bar as a local church.</p>
            </div>
            <div className="value-card">
              <div className="value-number">04</div>
              <h3>Rapid innovation</h3>
              <p>Continuous deployment to multi-environment infrastructure — new capabilities ship to 180+ countries without service interruptions.</p>
            </div>
          </div>
        </div>
      </div>

      {/* ── LIVE DEMO ───────────────────────────────────────── */}
      <LiveDemo />

      {/* ── FOOTER ──────────────────────────────────────────── */}
      <footer className="footer">
        <div className="footer-inner">
          <div className="footer-top">
            <div className="footer-brand">
              <div className="footer-brand-name">Renewed<span>Vision</span></div>
              <p>
                Building live production software since 2002. Trusted by
                houses of worship, broadcast networks, sports venues, and
                government institutions worldwide.
              </p>
              <div className="footer-social">
                <a href="#" aria-label="YouTube">▶</a>
                <a href="#" aria-label="Instagram">◎</a>
                <a href="#" aria-label="Facebook">f</a>
                <a href="#" aria-label="X / Twitter">𝕏</a>
              </div>
            </div>
            <div className="footer-col">
              <h4>Products</h4>
              <ul>
                <li><a href="#">ProPresenter</a></li>
                <li><a href="#">ProContent</a></li>
                <li><a href="#">ProVideoPlayer</a></li>
                <li><a href="#">Scoreboard</a></li>
              </ul>
            </div>
            <div className="footer-col">
              <h4>Learn</h4>
              <ul>
                <li><a href="#">Getting Started</a></li>
                <li><a href="#">Video Tutorials</a></li>
                <li><a href="#">Blog</a></li>
                <li><a href="#">Feature Requests</a></li>
              </ul>
            </div>
            <div className="footer-col">
              <h4>Support</h4>
              <ul>
                <li><a href="#">Help Center</a></li>
                <li><a href="#">System Requirements</a></li>
                <li><a href="#">Downloads</a></li>
                <li><a href="#">Release Notes</a></li>
              </ul>
            </div>
            <div className="footer-col">
              <h4>Company</h4>
              <ul>
                <li><a href="#">About</a></li>
                <li><a href="#">Careers</a></li>
                <li><a href="#">Press</a></li>
                <li><a href="#">Contact</a></li>
              </ul>
            </div>
          </div>
          <div className="footer-bottom">
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              <RegionBadge />
              <span>© {new Date().getFullYear()} Renewed Vision. All rights reserved. <em style={{ color: 'var(--text-dim)', fontStyle: 'normal' }}>— Platform demo.</em></span>
            </div>
            <div className="footer-legal">
              <a href="#">Privacy Policy</a>
              <a href="#">Terms of Service</a>
              <a href="#">Cookie Settings</a>
            </div>
          </div>
        </div>
      </footer>
    </>
  );
}
