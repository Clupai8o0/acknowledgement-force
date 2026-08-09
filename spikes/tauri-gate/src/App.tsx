import { useCallback, useEffect, useLayoutEffect, useRef, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import { AudioMeter, BAR_COUNT } from "./AudioMeter";
import { runSpring } from "./spring";

// --- content (spike copy; edit here) --------------------------------------
const CLAIM = ["I am someone who trains", "when I don't feel like it."];
const PROMPT_LEAD = "this morning you said:";
const PROMPT_QUOTE = '"gym after the 4pm shift"';
const TRANSCRIPT = "went after the shift. legs were dead, did the session anyway.";

type Mark = "kept" | "broken" | "unsettled";
/** the six days before today, oldest first */
const HISTORY: Mark[] = ["kept", "broken", "kept", "unsettled", "kept", "kept"];

type Phase = "idle" | "recording" | "settling" | "verdict" | "closing";

const TRANSCRIPT_DELAY_MS = 400;

function todayLabel(): string {
  const d = new Date();
  const wd = d.toLocaleDateString("en-GB", { weekday: "long" });
  const mo = d.toLocaleDateString("en-GB", { month: "long" });
  return `${wd}, ${d.getDate()} ${mo}`.toUpperCase();
}

function MarkDot({ mark, dim }: { mark: Mark | null; dim?: boolean }) {
  const cls = mark ? `mark mark-${mark}` : "mark mark-pending";
  return <span className={dim ? `${cls} is-dim` : cls} />;
}

export default function App() {
  const [phase, setPhase] = useState<Phase>("idle");
  const [today, setToday] = useState<Mark | null>(null);
  const [transcript, setTranscript] = useState<string | null>(null);
  const [elapsed, setElapsed] = useState(0);
  const [flying, setFlying] = useState<Mark | null>(null);

  const slotRef = useRef<HTMLSpanElement>(null);
  const actionRef = useRef<HTMLDivElement>(null);
  const flyRef = useRef<HTMLSpanElement>(null);
  const holdStart = useRef(0);
  const timers = useRef<number[]>([]);
  const auto = useRef(false);

  const after = (ms: number, fn: () => void) => {
    timers.current.push(window.setTimeout(fn, ms));
  };
  useEffect(() => () => timers.current.forEach(clearTimeout), []);

  // 2. press and hold ------------------------------------------------------
  const startHold = useCallback(() => {
    if (phase !== "idle") return;
    holdStart.current = performance.now();
    setElapsed(0);
    setPhase("recording");
  }, [phase]);

  // 3. release -------------------------------------------------------------
  const release = useCallback(() => {
    setPhase("settling");
    after(TRANSCRIPT_DELAY_MS, () => {
      setTranscript(TRANSCRIPT);
      setPhase("verdict");
    });
  }, []);

  const endHold = useCallback(() => {
    if (phase !== "recording") return;
    release();
  }, [phase, release]);

  useEffect(() => {
    if (phase !== "recording") return;
    const id = window.setInterval(
      () => setElapsed(performance.now() - holdStart.current),
      100,
    );
    return () => clearInterval(id);
  }, [phase]);

  // spike instrumentation: GATE_AUTODRIVE=<ms> holds the button by itself
  useEffect(() => {
    invoke<number>("autodrive_ms")
      .then((ms) => {
        invoke("diag", { msg: `autodrive=${ms}` });
        if (!ms) return;
        auto.current = true;
        after(600, () => {
          invoke("diag", { msg: "autodrive: hold" });
          holdStart.current = performance.now();
          setElapsed(0);
          setPhase("recording");
          after(ms, () => {
            invoke("diag", { msg: "autodrive: release" });
            release();
          });
        });
      })
      .catch((e) => invoke("diag", { msg: `autodrive failed ${e}` }));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    invoke("diag", { msg: `phase=${phase}` });
    if (phase === "verdict" && auto.current) after(1400, () => settle("kept"));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [phase]);

  // 4. settle: the day's mark springs into the strip ------------------------
  const settle = (mark: Mark) => {
    const from = actionRef.current?.getBoundingClientRect();
    const to = slotRef.current?.getBoundingClientRect();
    if (!from || !to) {
      setToday(mark);
      after(200, () => setPhase("closing"));
      return;
    }
    const x0 = from.left + from.width / 2;
    const y0 = from.top + from.height / 2;
    const x1 = to.left + to.width / 2;
    const y1 = to.top + to.height / 2;
    setFlying(mark);
    requestAnimationFrame(() =>
      runSpring((t) => {
        const el = flyRef.current;
        if (!el) return;
        const s = 1 + 1.4 * (1 - t);
        el.style.transform = `translate3d(${x0 + (x1 - x0) * t}px, ${
          y0 + (y1 - y0) * t
        }px, 0) translate(-50%, -50%) scale(${s})`;
      }, () => {
        setFlying(null);
        setToday(mark);
        after(260, () => setPhase("closing"));
      }),
    );
  };

  useLayoutEffect(() => {
    if (flying && flyRef.current) flyRef.current.style.opacity = "1";
  }, [flying]);

  // 5. not tonight: one tap, no confirm ------------------------------------
  const notTonight = () => {
    timers.current.forEach(clearTimeout);
    setToday("unsettled");
    setPhase("closing");
  };

  const recording = phase === "recording";
  const closing = phase === "closing";
  const secs = Math.floor(elapsed / 1000);

  return (
    <main className={`gate${closing ? " is-closing" : ""}`}>
      <header className="strip">
        <span className="date">{todayLabel()}</span>
        <span className="marks">
          {HISTORY.map((m, i) => (
            <MarkDot key={i} mark={m} dim={i < 3} />
          ))}
          <span ref={slotRef} className="slot">
            <MarkDot mark={today} />
          </span>
        </span>
      </header>

      <section className="body">
        <h1 className="claim">
          {CLAIM.map((line) => (
            <span key={line}>{line}</span>
          ))}
        </h1>

        <div className="prompt">
          <p>{PROMPT_LEAD}</p>
          <p className="quote">{PROMPT_QUOTE}</p>
        </div>

        <p className={`transcript${transcript ? " is-in" : ""}`}>{transcript}</p>
      </section>

      <footer className="foot">
        <div ref={actionRef} className="action">
          {phase === "verdict" ? (
            <div className="verdicts">
              <button className="verdict" onClick={() => settle("kept")}>
                KEPT
              </button>
              <button className="verdict" onClick={() => settle("broken")}>
                BROKEN
              </button>
            </div>
          ) : (
            <button
              className={`hold${recording ? " is-live" : ""}`}
              disabled={phase === "settling"}
              onPointerDown={(e) => {
                e.currentTarget.setPointerCapture(e.pointerId);
                startHold();
              }}
              onPointerUp={endHold}
              onPointerCancel={endHold}
            >
              <span className="hold-label">HOLD TO SPEAK</span>
              <span className="hold-meter">
                <AudioMeter active={recording} bars={BAR_COUNT} />
                <span className="timer">
                  {Math.floor(secs / 60)}:{String(secs % 60).padStart(2, "0")}
                </span>
              </span>
            </button>
          )}
        </div>

        <button className="skip" onClick={notTonight}>
          Not tonight
        </button>
      </footer>

      {flying && (
        <span ref={flyRef} className={`fly mark mark-${flying}`} aria-hidden />
      )}

      <div className="closing-note">
        <span>goodnight</span>
        {/* spike-only: lets the flow be re-run for measurements */}
        <button
          className="again"
          onClick={() => {
            setToday(null);
            setTranscript(null);
            setElapsed(0);
            setPhase("idle");
          }}
        >
          again
        </button>
      </div>
    </main>
  );
}
