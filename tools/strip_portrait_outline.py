#!/usr/bin/env python3
"""Remove the baked light silhouette outline from the v2 portraits.

The v2 strict-style art carries a 1–2px bone/grey outline around hair and
clothing. For every opaque pixel within two pixels of transparency, copy the
colour of the nearest fully-interior pixel. This keeps shirt/paper interiors
unchanged while the artificial rim takes the hair/coat/skin colour behind it.

Run: python tools/strip_portrait_outline.py
"""
from pathlib import Path
import shutil

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PORTRAITS = ROOT / "assets" / "portraits"


def erode4(mask: np.ndarray, iterations: int) -> np.ndarray:
    out = mask.copy()
    for _ in range(iterations):
        p = np.pad(out, 1, constant_values=False)
        out = out & p[:-2, 1:-1] & p[2:, 1:-1] & p[1:-1, :-2] & p[1:-1, 2:]
    return out


def process(path: Path) -> int:
    img = Image.open(path).convert("RGBA")
    arr = np.asarray(img).copy()
    opaque = arr[:, :, 3] > 0
    inner = erode4(opaque, 2)
    band = opaque & ~inner

    h, w = opaque.shape
    changed = 0
    for y, x in np.argwhere(band):
        best = None
        best_d = 999
        for radius in (1, 2, 3):
            for dy in range(-radius, radius + 1):
                for dx in range(-radius, radius + 1):
                    nx, ny = x + dx, y + dy
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    if not inner[ny, nx]:
                        continue
                    d = dx * dx + dy * dy
                    if d < best_d:
                        best_d = d
                        best = (nx, ny)
            if best is not None:
                break
        if best is None:
            continue
        if not np.array_equal(arr[y, x, :3], arr[best[1], best[0], :3]):
            arr[y, x, :3] = arr[best[1], best[0], :3]
            changed += 1
    if changed:
        Image.fromarray(arr, "RGBA").save(path)
    return changed


total = 0
for p in sorted(PORTRAITS.glob("d[1-7]s[1-4].png")):
    n = process(p)
    total += n
    shutil.copyfile(p, p.with_name(p.stem + "-blink.png"))
    print(f"{p.name}: stripped {n}")
print("total stripped pixels:", total)
