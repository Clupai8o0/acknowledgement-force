import Link from "next/link";
import LandingEffects from "./landing-effects";

const GH = "https://github.com/clupai8o0/force";

export default function Home() {
  return (
    <>
      {/* ============ NAV ============ */}
      <header className="nav">
        <nav className="nav-inner" aria-label="Primary">
          <a href="#top" className="brand" aria-label="Acknowledgement Force home">
            <span className="seal" aria-hidden="true">
              <img
                src="/assets/illustrations/icon.png"
                alt=""
                width={24}
                height={24}
                className="brand-icon"
              />
            </span>
            Acknowledgement{" "}Force
          </a>
          <div className="nav-links">
            <a href="#why">Why</a>
            <a href="#demo">Demo</a>
            <a href="#screens">Screens</a>
            <a href="#features">Features</a>
            <a href="#how">How</a>
          </div>
          <div className="nav-actions">
            <Link className="btn btn-ghost btn-sm" href="/login">
              Log in
            </Link>
            <button
              className="icon-btn theme-toggle"
              id="themeToggle"
              aria-label="Toggle dark mode"
            >
              <svg
                className="sun"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <circle cx="12" cy="12" r="4" />
                <path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
              </svg>
              <svg
                className="moon"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z" />
              </svg>
            </button>
            <a
              className="btn btn-primary btn-sm"
              href={GH}
              target="_blank"
              rel="noopener"
              data-gh
            >
              <svg viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 1C5.9 1 1 5.9 1 12c0 4.9 3.2 9 7.5 10.5.5.1.7-.2.7-.5v-1.7c-3 .7-3.7-1.4-3.7-1.4-.5-1.3-1.2-1.6-1.2-1.6-1-.7.1-.7.1-.7 1.1.1 1.7 1.1 1.7 1.1 1 1.7 2.6 1.2 3.2.9.1-.7.4-1.2.7-1.5-2.4-.3-5-1.2-5-5.4 0-1.2.4-2.2 1.1-2.9-.1-.3-.5-1.4.1-2.9 0 0 .9-.3 3 1.1.9-.2 1.8-.4 2.8-.4 1 0 1.9.1 2.8.4 2.1-1.4 3-1.1 3-1.1.6 1.5.2 2.6.1 2.9.7.7 1.1 1.7 1.1 2.9 0 4.2-2.6 5.1-5 5.4.4.3.8 1 .8 2.1v3c0 .3.2.6.7.5C19.8 21 23 16.9 23 12c0-6.1-4.9-11-11-11z" />
              </svg>
              GitHub
            </a>
            <button
              className="icon-btn menu-btn"
              id="menuBtn"
              aria-label="Open menu"
              aria-expanded="false"
            >
              <svg
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
              >
                <path d="M4 7h16M4 12h16M4 17h16" />
              </svg>
            </button>
          </div>
        </nav>
      </header>

      <div className="mobile-menu" id="mobileMenu">
        <a href="#why">Why</a>
        <a href="#demo">Demo</a>
        <a href="#screens">Screens</a>
        <a href="#features">Features</a>
        <a href="#how">How it works</a>
        <Link href="/login">Log in</Link>
        <a href={GH} target="_blank" rel="noopener" data-gh>
          GitHub ↗
        </a>
      </div>

      {/* ============ HERO ============ */}
      <main id="top">
        <section className="hero">
          <div className="rings" aria-hidden="true">
            <div className="glow"></div>
            <div className="ring r1"></div>
            <div className="ring r2"></div>
            <div className="ring r3"></div>
            <div className="ring r4"></div>
          </div>
          <div className="hero-content">
            <span className="badge">
              <span className="dot"></span>Free &amp; Open Source · macOS + Web
            </span>
            <h1 className="display">
              <span className="line">
                <span data-hero>Acknowledgement</span>
              </span>
              <span className="line">
                <span data-hero>Force</span>
              </span>
            </h1>
            <p className="lead" data-hero>
              A daily contract you must read and commit to before your Mac is
              yours. Read carefully. Acknowledge intentionally. Then take a deep
              breath.
            </p>
            <div className="hero-cta" data-hero>
              <a className="btn btn-primary" href="#demo">
                <svg
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M5 3l14 9-14 9V3z" />
                </svg>
                Watch the demo
              </a>
              <a className="btn btn-ghost" href={GH} target="_blank" rel="noopener" data-gh>
                View on GitHub
              </a>
            </div>
          </div>
          <a href="#why" className="scroll-cue" aria-hidden="true">
            <span>Scroll</span>
            <span className="bar"></span>
          </a>
        </section>

        {/* ============ MARQUEE ============ */}
        <div className="strip" aria-hidden="true">
          <div className="marquee">
            <span>Read carefully</span>
            <span>Acknowledge intentionally</span>
            <span>No escape until you commit</span>
            <span>One highest-leverage action</span>
            <span>Focus mode</span>
            <span>Read carefully</span>
            <span>Acknowledge intentionally</span>
            <span>No escape until you commit</span>
            <span>One highest-leverage action</span>
            <span>Focus mode</span>
          </div>
        </div>

        {/* ============ MANIFESTO / WHY ============ */}
        <section id="why" className="section-pad wrap">
          <div className="manifesto">
            <div className="reveal">
              <p className="eyebrow">The premise</p>
              <blockquote>
                Discipline isn&apos;t a feeling you wait for. It&apos;s a{" "}
                <em>contract</em> you sign — every single day, before the day
                gets to you.
              </blockquote>
              <p className="by">
                Acknowledgement Force gates your Mac behind your own words. The
                window won&apos;t close until you&apos;ve read today&apos;s
                contract, ticked the box, and named the one thing that matters
                most. Edit your contract, quotes, goals, and reflection from the
                web — it lands on your Mac on launch.
              </p>
            </div>
            <div className="illo reveal">
              <img
                src="/assets/illustrations/sign.png"
                alt="A hand signing a contract with a fountain pen"
                loading="lazy"
              />
            </div>
          </div>
        </section>

        {/* ============ VIDEO DEMO ============ */}
        <section id="demo" className="demo section-pad wrap">
          <div className="section-head center reveal">
            <span className="tick"></span>
            <p className="eyebrow">See it in motion</p>
            <h2 className="display">A calm, deliberate ritual</h2>
            <p>
              The breathing intro, the contract, the commitment. Drop your
              screen recording in below.
            </p>
          </div>
          <div className="window reveal">
            <div className="titlebar">
              <span className="lights">
                <i></i>
                <i></i>
                <i></i>
              </span>
              <span className="ttl">Acknowledgement Force</span>
            </div>
            <video
              className="demo-video"
              controls
              preload="metadata"
              aria-label="Acknowledgement Force demo"
            >
              <source src="/assets/demo.mp4" type="video/mp4" />
            </video>
          </div>
        </section>

        {/* ============ SCREENS / BENTO ============ */}
        <section id="screens" className="section-pad wrap">
          <div className="section-head reveal">
            <span className="tick"></span>
            <p className="eyebrow">Inside the app</p>
            <h2 className="display">Every surface, built like cotton paper</h2>
            <p>
              A strictly monochrome system where depth comes from stacked tonal
              layers — never borders. Here&apos;s the real thing, recreated
              pixel-faithful.
            </p>
          </div>

          <div className="bento">
            {/* The contract (locked) */}
            <div className="cell col-3 row-3 reveal">
              <div className="cell-pad mini-contract">
                <p className="kicker">The locked contract</p>
                <div className="doc">
                  <div className="doc-scroll">
                    <h4>I. Who I Am</h4>
                    <p
                      style={{
                        fontSize: ".84rem",
                        color: "var(--ash)",
                        marginBottom: "6px",
                      }}
                    >
                      I am building something that compounds. My success depends
                      on sustained performance, not bursts.
                    </p>
                    <div className="rule"></div>
                    <h4>II. Non-Negotiable Rules</h4>
                    <div className="num">
                      <b>1.</b>
                      <span>Protect sleep. Without it, everything else collapses.</span>
                    </div>
                    <div className="num">
                      <b>2.</b>
                      <span>Anxiety needs systems, not willpower.</span>
                    </div>
                    <div className="num">
                      <b>3.</b>
                      <span>Execution beats planning. Ship the work.</span>
                    </div>
                    <div className="num">
                      <b>4.</b>
                      <span>One project at a time. Finish before starting.</span>
                    </div>
                    <div className="rule"></div>
                    <h4>III. Daily Acknowledgement</h4>
                    <p style={{ fontSize: ".84rem", color: "var(--ash)" }}>
                      By opening this app, I commit to executing with discipline
                      and clarity today.
                    </p>
                  </div>
                </div>
                <div className="contract-foot">
                  <span className="cbox">
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="3"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <path d="M4 12l5 5L20 6" />
                    </svg>
                  </span>
                  <span>I have read &amp; acknowledge this contract for today</span>
                </div>
              </div>
            </div>

            {/* Dashboard: interactive checklist */}
            <div className="cell col-3 row-2 reveal">
              <div className="cell-pad">
                <div className="panel-head">
                  <h4>
                    Daily
                    <br />
                    Non-Negotiables
                  </h4>
                  <span className="progress-badge" id="progressBadge">
                    0/6
                  </span>
                </div>
                <ul className="checklist" id="checklist">
                  {[
                    "Sleep 7–8 hours",
                    "Move your body · 30 min",
                    "Deep work · one hard problem",
                    "Read · 15–30 minutes",
                    "Journal · 5–10 minutes",
                    "No doomscrolling · sit in silence",
                  ].map((label) => (
                    <li key={label}>
                      <button className="check-row" data-check>
                        <span className="check-dot">
                          <svg
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            strokeWidth="3"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                          >
                            <path d="M4 12l5 5L20 6" />
                          </svg>
                        </span>
                        <span className="lbl">{label}</span>
                      </button>
                    </li>
                  ))}
                </ul>
              </div>
            </div>

            {/* Today's action */}
            <div className="cell col-3 row-1 reveal">
              <div className="cell-pad action-card">
                <p className="kicker">Today&apos;s highest-leverage action</p>
                <p className="action" id="typeAction"></p>
              </div>
            </div>

            {/* Themes */}
            <div className="cell col-2 reveal">
              <div className="cell-pad">
                <p className="kicker">Themes</p>
                <h3>Light, Dark, System</h3>
                <div className="swatches">
                  <div className="sw light">
                    <span className="ttl">Light</span>
                  </div>
                  <div className="sw dark">
                    <span className="ttl">Dark</span>
                  </div>
                </div>
              </div>
            </div>

            {/* History */}
            <div className="cell col-4 reveal">
              <div className="cell-pad">
                <p className="kicker">Past actions · last 30 days</p>
                <div className="hist-row">
                  <span className="d">Mon 19</span>
                  <span className="a">Ship the auth refactor PR</span>
                </div>
                <div className="hist-row">
                  <span className="d">Sun 18</span>
                  <span className="a">Finish the portfolio case study</span>
                </div>
                <div className="hist-row">
                  <span className="d">Sat 17</span>
                  <span className="a">One hard algorithm problem, documented</span>
                </div>
              </div>
            </div>

            {/* Schedule */}
            <div className="cell col-3 reveal">
              <div className="cell-pad schedule">
                <p className="kicker">Re-lock schedule</p>
                <div className="segs" id="segs">
                  <button className="seg" data-detail="Re-acknowledge each time Force opens.">
                    Every launch
                  </button>
                  <button className="seg" data-detail="Re-locks one hour after each acknowledgement.">
                    Hourly
                  </button>
                  <button
                    className="seg active"
                    data-detail="One acknowledgement carries the whole day."
                  >
                    Once a day
                  </button>
                  <button className="seg" data-detail="One acknowledgement carries the whole week.">
                    Weekly
                  </button>
                  <button className="seg" data-detail="Re-acknowledge on every login and restart.">
                    On login
                  </button>
                </div>
                <p className="detail" id="scheduleDetail">
                  One acknowledgement carries the whole day.
                </p>
              </div>
            </div>

            {/* Sync */}
            <div className="cell col-3 reveal">
              <div className="cell-pad">
                <p className="kicker">Edit from anywhere</p>
                <h3>Four pieces, kept in sync.</h3>
                <div className="hist-row">
                  <span className="d">Contract</span>
                  <span className="a">Markdown — your rules, your words.</span>
                </div>
                <div className="hist-row">
                  <span className="d">Quotes</span>
                  <span className="a">A rotating reminder of why you do this.</span>
                </div>
                <div className="hist-row">
                  <span className="d">Goals</span>
                  <span className="a">Daily targets that reset each period.</span>
                </div>
                <div className="hist-row">
                  <span className="d">Reflect</span>
                  <span className="a">End-of-day note, kept just for you.</span>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ============ FEATURES ============ */}
        <section id="features" className="section-pad wrap">
          <div className="section-head center reveal">
            <span className="tick"></span>
            <p className="eyebrow">What it does</p>
            <h2 className="display">Built to hold you to your word</h2>
          </div>
          <div className="features">
            <div className="feature reveal">
              <div className="ico">
                <img
                  src="/assets/illustrations/lock.png"
                  alt="A laptop sealed with a padlock"
                  loading="lazy"
                />
              </div>
              <div>
                <h3>The no-escape gate</h3>
                <p>
                  The window refuses to close until today&apos;s contract is
                  acknowledged. Pair it with auto-launch on login and there&apos;s
                  no quiet way around your own rules.
                </p>
              </div>
            </div>
            <div className="feature reveal">
              <div className="ico">
                <img
                  src="/assets/illustrations/sign.png"
                  alt="A hand signing a contract"
                  loading="lazy"
                />
              </div>
              <div>
                <h3>Your contract, your words</h3>
                <p>
                  Write it in plain Markdown — headings, rules, checkboxes, bold.
                  Edit the motivation line and non-negotiables anytime. It&apos;s
                  a template, not a sermon.
                </p>
              </div>
            </div>
            <div className="feature reveal">
              <div className="ico">
                <img
                  src="/assets/illustrations/checklist.png"
                  alt="A checklist with ticked boxes"
                  loading="lazy"
                />
              </div>
              <div>
                <h3>Daily non-negotiables</h3>
                <p>
                  A living checklist that resets each period, with a progress
                  badge that fills as you go. Thirty days of past actions, always
                  one click away.
                </p>
              </div>
            </div>
            <div className="feature reveal">
              <div className="ico">
                <img
                  src="/assets/illustrations/breathe.png"
                  alt="A person meditating inside breathing rings"
                  loading="lazy"
                />
              </div>
              <div>
                <h3>A calmer cadence</h3>
                <p>
                  Breathing rings, soft-focus dissolves, spring physics
                  everywhere. Choose how often it re-locks — every launch,
                  hourly, daily, weekly, or on login.
                </p>
              </div>
            </div>
            <div className="feature reveal">
              <div className="ico">
                <img
                  src="/assets/illustrations/lock.png"
                  alt="A single line of focused text"
                  loading="lazy"
                />
              </div>
              <div>
                <h3>Focus mode</h3>
                <p>
                  One click puts today&apos;s highest-leverage action on a
                  quiet, breathing canvas — no chrome, no chatter, just the
                  words you wrote yourself. ESC to come back.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* ============ HOW IT WORKS ============ */}
        <section id="how" className="section-pad wrap">
          <div className="section-head reveal">
            <span className="tick"></span>
            <p className="eyebrow">The ritual</p>
            <h2 className="display">Three steps. Every day.</h2>
          </div>
          <div className="steps">
            <div className="step reveal">
              <div className="n">01</div>
              <span className="line-link"></span>
              <h3>Read</h3>
              <p>
                The contract scrolls into focus. You can&apos;t skip ahead — the
                acknowledgement only unlocks once you&apos;ve reached the bottom.
              </p>
            </div>
            <div className="step reveal">
              <div className="n">02</div>
              <span className="line-link"></span>
              <h3>Acknowledge</h3>
              <p>
                Tick the box. Name today&apos;s single highest-leverage action —
                the one thing that, done, makes the day a win.
              </p>
            </div>
            <div className="step reveal">
              <div className="n">03</div>
              <h3>Commit</h3>
              <p>
                Confirm, and your Mac is yours. Your action and streak are logged
                locally, and the dashboard greets you.
              </p>
            </div>
          </div>
        </section>

        {/* ============ TWO WAYS ============ */}
        <section className="section-pad wrap">
          <div className="section-head center reveal">
            <span className="tick"></span>
            <p className="eyebrow">Two ways to run it</p>
            <h2 className="display">Hosted, or your own backend.</h2>
            <p>Same Mac app. Pick the plumbing that fits.</p>
          </div>
          <div className="paths">
            <div className="path reveal">
              <p className="kicker">For non-technical users</p>
              <h3>Hosted — zero setup</h3>
              <p>
                Download the prebuilt app, create an account at
                force.clupai.com, log in. The build is pre-wired to the hosted
                backend, so editing on the web syncs to your Mac on launch.
              </p>
              <div className="path-cta">
                <Link className="btn btn-ghost btn-sm" href="/signup">
                  Create your account →
                </Link>
              </div>
            </div>
            <div className="path reveal">
              <p className="kicker">For developers</p>
              <h3>Self-host — your data, your keys</h3>
              <p>
                Point the app at your own Supabase project and own every byte.
                Or skip sync entirely and run it fully local — no account, no
                network. Same source, your infrastructure.
              </p>
              <div className="path-cta">
                <a className="btn btn-ghost btn-sm" href={GH} target="_blank" rel="noopener" data-gh>
                  Bring your own Supabase →
                </a>
              </div>
            </div>
          </div>
        </section>

        {/* ============ STATS ============ */}
        <section className="section-pad wrap">
          <div className="stats">
            <div className="stat reveal">
              <div className="v" data-count="100" data-suffix="%">
                0%
              </div>
              <div className="k">Local &amp; private</div>
            </div>
            <div className="stat reveal">
              <div className="v" data-count="0">
                0
              </div>
              <div className="k">Trackers</div>
            </div>
            <div className="stat reveal">
              <div className="v">∞</div>
              <div className="k">Editable contracts</div>
            </div>
            <div className="stat reveal">
              <div className="v">MIT</div>
              <div className="k">Open-source license</div>
            </div>
          </div>
        </section>

        {/* ============ CTA ============ */}
        <section className="cta-band section-pad wrap">
          <div className="cta-card reveal">
            <span className="ring-deco a" aria-hidden="true"></span>
            <span className="ring-deco b" aria-hidden="true"></span>
            <h2>Sign today&apos;s contract.</h2>
            <p>
              Acknowledgement Force is free, open source, and native to macOS.
              Clone it, read every line, make it yours.
            </p>
            <div className="cta-row">
              <Link className="btn btn-primary" href="/signup">
                Create your account
              </Link>
              <a className="btn btn-ghost" href={GH} target="_blank" rel="noopener" data-gh>
                Clone on GitHub
              </a>
            </div>
          </div>
        </section>
      </main>

      {/* ============ FOOTER ============ */}
      <footer className="footer">
        <div className="wrap">
          <div className="footer-grid">
            <div>
              <div className="brand">
                <span className="seal" aria-hidden="true">
                  <img
                    src="/assets/illustrations/icon.png"
                    alt=""
                    width={24}
                    height={24}
                    className="brand-icon"
                  />
                </span>
                Acknowledgement Force
              </div>
              <p className="note">
                A daily contract you must read and commit to before your Mac is
                yours. Native SwiftUI · macOS 14+.
              </p>
            </div>
            <div className="footer-links">
              <div className="footer-col">
                <h5>Product</h5>
                <a href="#why">Why</a>
                <a href="#demo">Demo</a>
                <a href="#screens">Screens</a>
                <a href="#features">Features</a>
              </div>
              <div className="footer-col">
                <h5>Account</h5>
                <Link href="/login">Log in</Link>
                <Link href="/signup">Sign up</Link>
                <a href={GH} target="_blank" rel="noopener" data-gh>
                  Repository
                </a>
                <a href={GH} target="_blank" rel="noopener" data-gh>
                  License (MIT)
                </a>
              </div>
            </div>
          </div>
          <div className="footer-base">
            <span>
              © <span id="year"></span> Acknowledgement Force. Free &amp; open
              source.
            </span>
            <span>Read carefully. Acknowledge intentionally.</span>
          </div>
        </div>
      </footer>

      <LandingEffects />
    </>
  );
}
