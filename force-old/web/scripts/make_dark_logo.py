#!/usr/bin/env python3
"""Create a dark-mode variant of the brand logo.

The logo is near-black ink (#1A1C1C) on transparent — built for light surfaces.
This recolors the ink to the design system's dark-mode ink (#F2F2F0) while
preserving the original alpha, so the mark reads cleanly on dark backgrounds.

Writes `icon-dark.png` next to each source. Run from anywhere:
    python3 web/scripts/make_dark_logo.py
"""
from pathlib import Path
from PIL import Image

DARK_INK = (242, 242, 240)  # #F2F2F0 — [data-theme="dark"] --ink

ROOT = Path(__file__).resolve().parents[2]
# Keep the web app and the legacy landing copies in sync.
SOURCES = [
    ROOT / "web/public/assets/illustrations/icon.png",
    ROOT / "landing/assets/illustrations/icon.png",
]


def make_dark(src: Path) -> None:
    img = Image.open(src).convert("RGBA")
    alpha = img.getchannel("A")
    dark = Image.new("RGBA", img.size, (*DARK_INK, 0))
    dark.putalpha(alpha)  # uniform light ink, original silhouette
    dst = src.with_name(src.stem + "-dark.png")
    dark.save(dst)
    print(f"{src.relative_to(ROOT)} -> {dst.name}  ({img.size[0]}x{img.size[1]})")


def main() -> None:
    for src in SOURCES:
        if src.exists():
            make_dark(src)
        else:
            print("skip (missing):", src.relative_to(ROOT))


if __name__ == "__main__":
    main()
