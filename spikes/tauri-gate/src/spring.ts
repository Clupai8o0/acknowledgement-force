/**
 * Minimal critically-ish damped spring, integrated on rAF with fixed substeps.
 * Tuned to SwiftUI's `.spring(response: 0.45, dampingFraction: 0.72)` so the
 * settle lands in ~600ms. No animation dependency.
 */
const RESPONSE = 0.45;
const DAMPING_FRACTION = 0.72;

const omega = (2 * Math.PI) / RESPONSE;
const stiffness = omega * omega;
const damping = 2 * DAMPING_FRACTION * omega;
const SUBSTEP = 1 / 480;

export function runSpring(
  onFrame: (t: number) => void,
  onDone?: () => void,
): () => void {
  let x = 0;
  let v = 0;
  let last = performance.now();
  let raf = 0;
  let cancelled = false;

  const tick = (now: number) => {
    let dt = Math.min((now - last) / 1000, 1 / 15);
    last = now;
    while (dt > 0) {
      const h = Math.min(SUBSTEP, dt);
      v += (stiffness * (1 - x) - damping * v) * h;
      x += v * h;
      dt -= h;
    }
    if (Math.abs(1 - x) < 0.001 && Math.abs(v) < 0.01) {
      onFrame(1);
      if (!cancelled) onDone?.();
      return;
    }
    onFrame(x);
    raf = requestAnimationFrame(tick);
  };

  raf = requestAnimationFrame(tick);
  return () => {
    cancelled = true;
    cancelAnimationFrame(raf);
  };
}
