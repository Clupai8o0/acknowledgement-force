import { useEffect, useRef } from "react";
import { invoke } from "@tauri-apps/api/core";

const say = (msg: string) => invoke("diag", { msg }).catch(() => {});

export const BAR_COUNT = 40;

const FFT = 2048;
const LOW_BIN = 2; // ~47 Hz
const HIGH_BIN = 150; // ~3.5 kHz, where a voice actually lives
const GAIN = 5;
const SHAPE = 0.7; // how much of a bar's height is spectral shape vs envelope
const SMOOTH = 0.4; // how much of the previous frame each bar keeps
const MIN_SCALE = 0.06;

/** log-spaced band edges across the analyser bins */
const EDGES = Array.from({ length: BAR_COUNT + 1 }, (_, i) =>
  Math.round(LOW_BIN * Math.pow(HIGH_BIN / LOW_BIN, i / BAR_COUNT)),
);

type Rig = {
  ctx: AudioContext;
  analyser: AnalyserNode;
  stream: MediaStream;
  pcm: Uint8Array<ArrayBuffer>;
  freq: Uint8Array<ArrayBuffer>;
};

let rigPromise: Promise<Rig> | null = null;

function getRig(): Promise<Rig> {
  if (!rigPromise) {
    rigPromise = navigator.mediaDevices
      .getUserMedia({
        audio: { echoCancellation: false, noiseSuppression: false },
      })
      .then((stream) => {
        const ctx = new AudioContext();
        const analyser = ctx.createAnalyser();
        analyser.fftSize = FFT;
        analyser.smoothingTimeConstant = 0.4;
        analyser.minDecibels = -85;
        analyser.maxDecibels = -25;
        ctx.createMediaStreamSource(stream).connect(analyser);
        say(
          `mic granted: "${stream.getAudioTracks()[0]?.label}" sr=${ctx.sampleRate}`,
        );
        return {
          ctx,
          analyser,
          stream,
          pcm: new Uint8Array(analyser.fftSize),
          freq: new Uint8Array(analyser.frequencyBinCount),
        };
      })
      .catch((err) => {
        rigPromise = null;
        throw err;
      });
  }
  return rigPromise;
}

/**
 * 40 bars driven by real microphone amplitude at rAF rate: each bar is the RMS
 * of one slice of the newest ~21ms of PCM, so the whole row moves with the
 * voice. The loop writes `transform` straight onto the bar nodes via refs —
 * React renders the bars once and never re-renders them, which is the
 * idiomatic way to run a 60fps visualiser in React.
 */
export function AudioMeter({ active, bars }: { active: boolean; bars: number }) {
  const rowRef = useRef<HTMLSpanElement>(null);
  const levels = useRef<Float32Array>(new Float32Array(bars));

  useEffect(() => {
    const nodes = rowRef.current
      ? (Array.from(rowRef.current.children) as HTMLElement[])
      : [];

    if (!active) {
      levels.current.fill(0);
      for (const n of nodes) n.style.transform = `scaleY(${MIN_SCALE})`;
      getRig()
        .then(({ ctx }) => ctx.suspend())
        .catch(() => {});
      return;
    }

    let raf = 0;
    let rig: Rig | null = null;
    let dead = false;

    getRig()
      .then((r) => {
        if (dead) return;
        rig = r;
        if (r.ctx.state !== "running") r.ctx.resume();
      })
      .catch((err) => say(`mic DENIED: ${err}`));

    let frames = 0;
    let peakSeen = 0;
    let lastReport = performance.now();

    const tick = () => {
      raf = requestAnimationFrame(tick);
      frames++;
      const now = performance.now();
      if (now - lastReport > 1000) {
        say(
          `meter ${frames} frames/s, peak level ${peakSeen.toFixed(2)}` +
            (rig ? "" : " (no audio rig yet)"),
        );
        frames = 0;
        peakSeen = 0;
        lastReport = now;
      }
      if (!rig) return;

      // overall loudness this frame, straight off the PCM
      rig.analyser.getByteTimeDomainData(rig.pcm);
      let sum = 0;
      for (let s = 0; s < rig.pcm.length; s++) {
        const d = (rig.pcm[s] - 128) / 128;
        sum += d * d;
      }
      const env = Math.min(
        1,
        Math.pow(Math.sqrt(sum / rig.pcm.length) * GAIN, 0.75),
      );
      if (env > peakSeen) peakSeen = env;

      // spectral shape across the bars, scaled by that loudness
      rig.analyser.getByteFrequencyData(rig.freq);
      const lv = levels.current;
      for (let i = 0; i < bars; i++) {
        let peak = 0;
        for (let b = EDGES[i]; b < Math.max(EDGES[i + 1], EDGES[i] + 1); b++) {
          if (rig.freq[b] > peak) peak = rig.freq[b];
        }
        const target = env * (1 - SHAPE + SHAPE * (peak / 255));
        lv[i] = lv[i] * SMOOTH + target * (1 - SMOOTH);
        const node = nodes[i];
        if (node) {
          node.style.transform = `scaleY(${Math.max(MIN_SCALE, lv[i])})`;
        }
      }
    };
    raf = requestAnimationFrame(tick);

    return () => {
      dead = true;
      cancelAnimationFrame(raf);
    };
  }, [active, bars]);

  return (
    <span ref={rowRef} className="meter">
      {Array.from({ length: bars }, (_, i) => (
        <span key={i} className="bar" />
      ))}
    </span>
  );
}
