#!/usr/bin/env python3
"""Generate the 1024px App Store icon for 大肥鱼热线."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "FatFishCall" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon.png"

S = 2048
FINAL = 1024


def lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(size: int, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGB", (size, size), top)
    draw = ImageDraw.Draw(image)
    for y in range(size):
        draw.line([(0, y), (size, y)], fill=lerp(top, bottom, y / (size - 1)))
    return image


def radial_glow(size: int, center: tuple[int, int], radius: int, color: tuple[int, int, int, int]) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    steps = 70
    for i in range(steps, 0, -1):
        r = radius * i / steps
        alpha = int(color[3] * (1 - i / steps) ** 1.7)
        draw.ellipse(
            [center[0] - r, center[1] - r, center[0] + r, center[1] + r],
            fill=(color[0], color[1], color[2], alpha),
        )
    return layer.filter(ImageFilter.GaussianBlur(18))


def main() -> None:
    base = vertical_gradient(S, (3, 14, 26), (7, 55, 82)).convert("RGBA")

    # Soft underwater glow.
    base = Image.alpha_composite(
        base,
        radial_glow(S, (1350, 980), 920, (70, 205, 255, 110)),
    )
    base = Image.alpha_composite(
        base,
        radial_glow(S, (500, 1500), 780, (60, 230, 190, 55)),
    )

    # Background bubbles.
    bubbles = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bubbles)
    for x, y, r, alpha in [
        (360, 430, 32, 48),
        (470, 300, 16, 40),
        (1720, 420, 22, 36),
        (1860, 650, 42, 30),
        (300, 900, 20, 28),
        (1640, 1500, 18, 30),
        (560, 1750, 28, 22),
    ]:
        bd.ellipse([x - r, y - r, x + r, y + r], fill=(210, 250, 255, alpha))
        bd.ellipse(
            [x - r, y - r, x + r, y + r],
            outline=(225, 255, 255, min(255, alpha + 35)),
            width=max(2, r // 8),
        )
    base = Image.alpha_composite(base, bubbles)

    # Tail.
    tail = [
        (900, 1040),
        (560, 760),
        (650, 965),
        (610, 1060),
        (650, 1155),
        (560, 1340),
    ]
    tail_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    td = ImageDraw.Draw(tail_layer)
    td.polygon(tail, fill=(39, 151, 208, 255))
    td.line(tail + [tail[0]], fill=(170, 240, 255, 120), width=10, joint="curve")
    base = Image.alpha_composite(base, tail_layer)

    # A soft shadow under the fish.
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse([720, 1320, 1810, 1600], fill=(0, 10, 20, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(55))
    base = Image.alpha_composite(base, shadow)

    # Body gradient clipped to an ellipse.
    body_box = (760, 590, 1810, 1430)
    body_mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(body_mask).ellipse(body_box, fill=255)
    body_gradient = vertical_gradient(S, (112, 224, 255), (19, 100, 160)).convert("RGBA")
    base = Image.composite(body_gradient, base, body_mask)

    body_draw = ImageDraw.Draw(base)
    body_draw.ellipse(body_box, outline=(210, 250, 255, 190), width=11)

    # Belly.
    belly_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    belly_draw = ImageDraw.Draw(belly_layer)
    belly_draw.ellipse([1000, 1055, 1700, 1350], fill=(222, 250, 255, 225))
    belly_layer = belly_layer.filter(ImageFilter.GaussianBlur(4))
    base = Image.alpha_composite(base, belly_layer)

    # Dorsal fin.
    fin_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fin_layer)
    fd.ellipse([1230, 520, 1500, 700], fill=(59, 177, 225, 255))
    fin_layer = fin_layer.rotate(-18, resample=Image.Resampling.BICUBIC, center=(1365, 610))
    base = Image.alpha_composite(base, fin_layer)

    # Side fin.
    side_fin = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sfd = ImageDraw.Draw(side_fin)
    sfd.ellipse([850, 1115, 1080, 1225], fill=(35, 164, 216, 255))
    side_fin = side_fin.rotate(28, resample=Image.Resampling.BICUBIC, center=(965, 1170))
    base = Image.alpha_composite(base, side_fin)

    # Body highlight.
    highlight = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    hd = ImageDraw.Draw(highlight)
    hd.ellipse([900, 690, 1280, 850], fill=(235, 255, 255, 55))
    highlight = highlight.rotate(-14, resample=Image.Resampling.BICUBIC, center=(1090, 770))
    highlight = highlight.filter(ImageFilter.GaussianBlur(24))
    base = Image.alpha_composite(base, highlight)

    draw = ImageDraw.Draw(base)

    # Blush.
    for cx in (1390, 1750):
        draw.ellipse([cx - 92, 1110, cx + 92, 1210], fill=(255, 135, 160, 95))

    # Eyes.
    for cx in (1435, 1635):
        draw.ellipse([cx - 82, 825, cx + 82, 1105], fill=(4, 24, 38, 255))
        draw.ellipse([cx - 55, 855, cx - 8, 930], fill=(255, 255, 255, 245))
        draw.ellipse([cx + 22, 1000, cx + 52, 1035], fill=(255, 255, 255, 140))

    # Smile.
    draw.arc([1480, 1070, 1660, 1190], start=20, end=160, fill=(5, 28, 42, 235), width=16)
    draw.arc([1515, 1090, 1625, 1170], start=25, end=155, fill=(255, 145, 166, 200), width=9)

    # A few foreground Bubbles.
    for x, y, r, alpha in [
        (1510, 560, 38, 100),
        (1605, 455, 24, 80),
        (1690, 365, 15, 60),
    ]:
        draw.ellipse([x - r, y - r, x + r, y + r], fill=(225, 255, 255, alpha))
        draw.ellipse(
            [x - r, y - r, x + r, y + r],
            outline=(240, 255, 255, min(255, alpha + 70)),
            width=max(2, r // 9),
        )

    # Bottom water lines.
    lines = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lines)
    for y, alpha, width in [(1770, 28, 9), (1840, 18, 7), (1910, 12, 6)]:
        points = []
        for x in range(0, S + 40, 40):
            points.append((x, y + math.sin(x / 230.0) * 20))
        ld.line(points, fill=(190, 245, 255, alpha), width=width, joint="curve")
    base = Image.alpha_composite(base, lines)

    # Nudge colors toward a richer, less flat look.
    base = base.filter(ImageFilter.UnsharpMask(radius=3, percent=40, threshold=2))
    base = base.convert("RGB").resize((FINAL, FINAL), Image.Resampling.LANCZOS)
    base.save(OUT, "PNG", optimize=True)
    print(f"wrote {OUT} ({base.size[0]}x{base.size[1]})")


if __name__ == "__main__":
    main()
