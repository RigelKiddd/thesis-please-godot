#!/usr/bin/env python3
"""Generate the four administrative paper stocks used by the request packet.

Run: python tools/make_paper_textures.py
Outputs 256x256 tiling PNGs in assets/textures/.
"""
from pathlib import Path
import random
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "textures"
OUT.mkdir(parents=True, exist_ok=True)
SIZE = 256


def fiber_texture(base, fibers, count=1400, seed=1):
    random.seed(seed)
    img = Image.new("RGB", (SIZE, SIZE), base)
    draw = ImageDraw.Draw(img, "RGBA")
    for _ in range(count):
        x = random.randrange(SIZE)
        y = random.randrange(SIZE)
        length = random.randrange(2, 12)
        color = random.choice(fibers)
        horizontal = random.random() < 0.6
        if horizontal:
            draw.line((x, y, x + length, y), fill=color, width=1)
        else:
            draw.line((x, y, x, y + length), fill=color, width=1)
    # subtle large-scale stains
    for _ in range(18):
        x = random.randrange(SIZE)
        y = random.randrange(SIZE)
        r = random.randrange(10, 38)
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(0, 0, 0, 3))
    return img


def certificate():
    img = fiber_texture((244, 236, 215), [(180, 160, 118, 18), (255, 252, 238, 42)], 1600, 7)
    return img


def cardstock():
    img = fiber_texture((217, 185, 138), [(120, 82, 52, 28), (246, 220, 172, 36)], 1900, 11)
    draw = ImageDraw.Draw(img, "RGBA")
    for _ in range(30):
        x = random.randrange(SIZE)
        y = random.randrange(SIZE)
        draw.rectangle((x, y, x + 1, y + 1), fill=(90, 55, 32, 60))
    return img


def carbonless():
    img = fiber_texture((220, 232, 238), [(120, 150, 165, 18), (250, 253, 255, 30)], 900, 23)
    draw = ImageDraw.Draw(img, "RGBA")
    # faint horizontal ruling, as on a carbonless form pad
    for y in range(24, SIZE, 22):
        draw.line((0, y, SIZE, y), fill=(70, 110, 135, 26), width=1)
    return img


def mimeo():
    """Coarse, slightly blue-grey school notice stock: cheap mimeograph paper."""
    img = fiber_texture((229, 226, 214), [(150, 150, 145, 22), (250, 249, 240, 34)], 2100, 31)
    draw = ImageDraw.Draw(img, "RGBA")
    # uneven duplicator ink ghosts and roller streaks
    for _ in range(26):
        x = random.randrange(SIZE)
        y = random.randrange(SIZE)
        r = random.randrange(6, 26)
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(66, 78, 82, 5))
    for x in range(6, SIZE, 37):
        draw.line((x, 0, x, SIZE), fill=(120, 128, 128, 7), width=1)
    for _ in range(90):
        x = random.randrange(SIZE)
        y = random.randrange(SIZE)
        draw.point((x, y), fill=(40, 44, 42, 24))
    return img


for name, fn in (
    ("paper_certificate.png", certificate),
    ("paper_cardstock.png", cardstock),
    ("paper_carbonless.png", carbonless),
    ("paper_mimeo.png", mimeo),
):
    path = OUT / name
    fn().save(path)
    print("wrote", path)
