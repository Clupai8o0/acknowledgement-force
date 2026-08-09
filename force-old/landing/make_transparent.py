#!/usr/bin/env python3
"""Turn white-background line art into transparent PNGs that keep only the black lines.

Luminance becomes alpha (white -> transparent, black -> opaque), the ink is
recolored to the app's near-black (#1A1C1C), and the result is auto-trimmed.
"""
from pathlib import Path
from PIL import Image

RAW = Path(__file__).parent / "assets" / "raw"
OUT = Path(__file__).parent / "assets" / "illustrations"
OUT.mkdir(parents=True, exist_ok=True)

INK = (26, 28, 28)        # #1A1C1C — never pure black, matches the design system
WHITE_CUTOFF = 235        # luminance >= this is treated as pure background
BLACK_CUTOFF = 90         # luminance <= this is treated as a solid line
PAD = 24                  # transparent breathing room after trim


def to_alpha(lum: int) -> int:
    """Map a pixel's luminance to an alpha value with a clean threshold ramp."""
    if lum >= WHITE_CUTOFF:
        return 0
    if lum <= BLACK_CUTOFF:
        return 255
    span = WHITE_CUTOFF - BLACK_CUTOFF
    return round((WHITE_CUTOFF - lum) / span * 255)


def process(src: Path) -> None:
    img = Image.open(src).convert("RGBA")
    px = img.load()
    w, h = img.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            lum = (r * 299 + g * 587 + b * 114) // 1000
            alpha = to_alpha(lum)
            if a < 255:
                alpha = alpha * a // 255
            if alpha:
                op[x, y] = (*INK, alpha)

    bbox = out.getbbox()
    if bbox:
        l, t, r, b = bbox
        l, t = max(0, l - PAD), max(0, t - PAD)
        r, b = min(w, r + PAD), min(h, b + PAD)
        out = out.crop((l, t, r, b))
    dst = OUT / src.name
    out.save(dst)
    print(f"{src.name:16} -> {dst.relative_to(dst.parents[2])}  ({out.size[0]}x{out.size[1]})")


def main() -> None:
    files = sorted(RAW.glob("*.png"))
    if not files:
        print("No source images in", RAW)
        return
    for f in files:
        process(f)


if __name__ == "__main__":
    main()
