import { StrictMode } from "react";
import ReactDOM from "react-dom/client";
import { invoke } from "@tauri-apps/api/core";
import App from "./App";
import "./App.css";

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
  <StrictMode>
    <App />
  </StrictMode>,
);

// --- cold-start instrumentation -------------------------------------------
// Reports the wall-clock instant of the first painted frame that already has
// the real fonts in it. Rust prints its own instants; a launcher script
// subtracts them. Spike-only; delete with the rest of this build.
const say = (msg: string) => invoke("diag", { msg }).catch(() => {});
const mark = (name: string, epochMs: number) =>
  invoke("mark_js", { name, epochMs }).catch(() => {});

// The engine's own paint timestamp. Unlike rAF this still fires when the
// window is occluded, so the launch measurement does not depend on the app
// winning focus.
new PerformanceObserver((list) => {
  for (const e of list.getEntries()) {
    mark(e.name.replace(/-/g, "_"), performance.timeOrigin + e.startTime);
  }
}).observe({ type: "paint", buffered: true });

// Secondary mark: first rAF frame after the real fonts are in. Needs the
// window to be visible.
document.fonts.ready.then(() => {
  requestAnimationFrame(() =>
    requestAnimationFrame(() =>
      mark("fonts_frame", performance.timeOrigin + performance.now()),
    ),
  );
});

say(
  `origin=${location.origin} secureContext=${window.isSecureContext} ` +
    `mediaDevices=${!!navigator.mediaDevices} ` +
    `getUserMedia=${!!navigator.mediaDevices?.getUserMedia} ` +
    `AudioContext=${typeof AudioContext} dpr=${devicePixelRatio}`,
);
addEventListener("load", () =>
  say(
    `window screenX=${screenX} screenY=${screenY} outer=${outerWidth}x${outerHeight} inner=${innerWidth}x${innerHeight}`,
  ),
);
window.addEventListener("error", (e) => say(`window.error ${e.message}`));
(["log", "warn", "error"] as const).forEach((k) => {
  const orig = console[k];
  console[k] = (...args: unknown[]) => {
    orig(...args);
    say(`console.${k} ${args.map((a) => String(a)).join(" ")}`);
  };
});
