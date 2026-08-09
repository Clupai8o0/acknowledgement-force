#!/usr/bin/env python3
"""Cold start -> first paint, N runs.

t0 is taken in this process immediately before exec of the bundled binary, so
the number includes dyld, the Rust runtime, WKWebView spin-up, asset load,
React mount, font load and one full painted frame.
"""
import subprocess, sys, time, statistics, os, signal

BIN = sys.argv[1] if len(sys.argv) > 1 else (
    "src-tauri/target/release/bundle/macos/tauri-gate.app/Contents/MacOS/tauri-gate"
)
RUNS = int(sys.argv[2]) if len(sys.argv) > 2 else 5

rows = []
for i in range(RUNS):
    t0 = time.time_ns()
    p = subprocess.Popen([BIN], stderr=subprocess.PIPE, stdout=subprocess.DEVNULL)
    marks = {}
    deadline = time.time() + 20
    while "first_paint" not in marks and time.time() < deadline:
        line = p.stderr.readline()
        if not line:
            break
        line = line.decode("utf8", "replace").strip()
        if line.startswith("PERF "):
            _, label, ns = line.split()
            marks[label] = int(ns)
        else:
            print("   ", line, file=sys.stderr)
    p.send_signal(signal.SIGKILL)
    p.wait()
    if "first_paint" not in marks:
        print(f"run {i+1}: FAILED (marks={marks})")
        continue
    row = {k: (v - t0) / 1e6 for k, v in marks.items()}
    rows.append(row)
    print(f"run {i+1}: main {row.get('main', 0):.0f}ms  setup {row.get('setup', 0):.0f}ms"
          f"  first_paint {row['first_paint']:.0f}ms")
    time.sleep(1.5)

if rows:
    for k in ("main", "setup", "first_paint"):
        vals = sorted(r[k] for r in rows if k in r)
        print(f"{k:12s} median {statistics.median(vals):7.1f}ms   "
              f"min {min(vals):.1f}  max {max(vals):.1f}   n={len(vals)}")
