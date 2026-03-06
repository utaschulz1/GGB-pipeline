#!/usr/bin/env python3
"""
make_grid.py — combine step images into a grid.

Usage:
    python3 lib/make_grid.py <glob_pattern> <cols> <rows> <output_file>

Example (2 rows × 4 cols from chili step images):
    python3 lib/make_grid.py "images/chili-sin-carne/[1-8]_*.jpg" 4 2 images/chili-sin-carne/steps_grid.jpg
"""

import sys
import glob
from PIL import Image

pattern  = sys.argv[1]
cols     = int(sys.argv[2])
rows     = int(sys.argv[3])
out_path = sys.argv[4]

files = sorted(glob.glob(pattern))
if not files:
    sys.exit(f"No files matched: {pattern}")
if len(files) != cols * rows:
    print(f"Warning: found {len(files)} images, expected {cols * rows}")

# Cell size: square, derived from the first image's shorter side
with Image.open(files[0]) as im:
    side = min(im.width, im.height)

cell = side  # each cell is side × side pixels

grid = Image.new("RGB", (cols * cell, rows * cell), (255, 255, 255))

for idx, path in enumerate(files[:cols * rows]):
    with Image.open(path) as im:
        # Centre-crop to square
        w, h = im.width, im.height
        s = min(w, h)
        left   = (w - s) // 2
        top    = (h - s) // 2
        im = im.crop((left, top, left + s, top + s))
        im = im.resize((cell, cell), Image.LANCZOS)
        col = idx % cols
        row = idx // cols
        grid.paste(im, (col * cell, row * cell))

grid.save(out_path, quality=90)
print(f"Saved {cols}×{rows} grid → {out_path}  ({grid.width}×{grid.height}px)")
