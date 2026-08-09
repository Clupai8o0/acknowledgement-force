#!/usr/bin/env python3
"""Rebuild the five Force design pages from their parts.

This is the recovered v1 of build_demo.py, widened to cover all three multi-part
pages and to regenerate the two asset files that were never snapshotted.

    python3 design/build.py            # writes design/built/

The original pipeline kept fonts_b64.json and masks_b64.json as pre-baked files.
Those were produced with Bash and so were never captured by file history; they are
regenerated here from fonts and images that are still in the repo. Everything is
inlined as base64 — no page fetches anything at run time.

Fraunces-Italic is the one asset with no other copy in the repo. It lives in
design/assets/ and came from google/fonts (SIL OFL). Roman Fraunces and Inter are
read from spikes/flutter-showcase/assets/fonts/ so they are not duplicated.
"""

import base64
import io
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent
REPO = ROOT.parent
OUT = ROOT / "built"

# Characters used across all three pages are a 110-glyph subset of Latin. The
# subset below is that set plus a wide margin, so late copy edits do not silently
# produce tofu. Subsetting takes the three fonts from 1.6 MB to 380 KB.
UNICODES = (
    "U+0020-007E,U+00A0-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,"
    "U+2000-206F,U+2074,U+20AC,U+2122,U+2190-2193,U+2212,U+2500-257F,U+2713-2714,"
    "U+25A0-25FF"
)

FONTS = {
    "Fraunces": REPO / "spikes/flutter-showcase/assets/fonts/Fraunces.ttf",
    "FrauncesIt": ROOT / "assets/Fraunces-Italic.ttf",
    "Inter": REPO / "spikes/flutter-showcase/assets/fonts/Inter.ttf",
}

# The engraving is recoloured through its own luminance as a mask, so only the
# alpha channel is ever read (D16, D24). The -alpha PNGs already carry the line
# art in alpha. 768 px covers the largest on-screen use (330 px) at 2x.
MASKS = {
    "tally": REPO / "spikes/illustration/eng-tally-alpha.png",
    "hand": REPO / "spikes/illustration/eng-hand-alpha.png",
}
MASK_PX = 768

# Multi-part pages, in concatenation order (parts sort lexically by filename).
PAGES = {
    "force-desktop-demo": "demo",
    "force-whole-shape": "flow",
    "force-the-screens": "ui",
}

STANDALONE = ["force-motion-lab", "force-wireframe-walkthrough"]


def build_fonts():
    out = {}
    for name, path in FONTS.items():
        dst = OUT / f"_sub-{name}.woff2"
        subprocess.run(
            ["pyftsubset", str(path), f"--unicodes={UNICODES}", "--flavor=woff2",
             "--layout-features=*", "--no-hinting", "--desubroutinize",
             f"--output-file={dst}"],
            check=True, capture_output=True,
        )
        out[name] = base64.b64encode(dst.read_bytes()).decode("ascii")
        dst.unlink()
    return out


def build_masks():
    from PIL import Image
    out = {}
    for name, path in MASKS.items():
        im = Image.open(path).convert("RGBA").resize((MASK_PX, MASK_PX), Image.LANCZOS)
        buf = io.BytesIO()
        im.save(buf, format="WEBP", lossless=True, quality=100, method=6)
        out[name] = base64.b64encode(buf.getvalue()).decode("ascii")
    return out


def wrap(body):
    """The wrapper build_demo.py used for its own local test file. Published
    artifacts do not need it — the publisher supplies the skeleton — so the
    .body.html files are what gets published and these are what you open."""
    return (
        '<!doctype html><html lang="en"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        '<style>*{margin:0;padding:0}img,canvas{display:block;max-width:100%}</style>'
        "</head><body>\n" + body + "\n</body></html>"
    )


def main():
    OUT.mkdir(exist_ok=True)
    fonts, masks = build_fonts(), build_masks()
    (ROOT / "fonts_b64.json").write_text(json.dumps(fonts))
    (ROOT / "masks_b64.json").write_text(json.dumps(masks))

    sub = {
        "__FRAUNCES__": fonts["Fraunces"],
        "__FRAUNCES_IT__": fonts["FrauncesIt"],
        "__INTER__": fonts["Inter"],
        "__MASK_TALLY__": masks["tally"],
        "__MASK_HAND__": masks["hand"],
    }

    failed = False
    for name, sub_dir in PAGES.items():
        parts = sorted((ROOT / "parts" / sub_dir).glob("*.html"))
        body = "\n".join(p.read_text(encoding="utf-8") for p in parts)
        for k, v in sub.items():
            body = body.replace(k, v)
        failed |= emit(name, body, len(parts))

    for name in STANDALONE:
        body = (ROOT / "standalone" / f"{name}.html").read_text(encoding="utf-8")
        for k, v in sub.items():
            body = body.replace(k, v)
        failed |= emit(name, body, 1)

    return 1 if failed else 0


def emit(name, body, n_parts):
    import re
    left = re.findall(r"__[A-Z_]+__", body)
    (OUT / f"{name}.body.html").write_text(body, encoding="utf-8")
    (OUT / f"{name}.html").write_text(wrap(body), encoding="utf-8")
    flag = "" if not left else f"  UNFILLED {sorted(set(left))}"
    print(f"  {name:<30} {len(body)/1024:>7,.0f} KB from {n_parts:>2} part(s){flag}")
    return bool(left)


if __name__ == "__main__":
    sys.exit(main())
