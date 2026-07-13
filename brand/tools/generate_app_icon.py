#!/usr/bin/env python3
"""Generate Atlas app icon PNG from Architectural identity spec."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

# Brand colors
WARM_OFF_WHITE = (250, 247, 242)
MIDNIGHT_BLUE = (26, 35, 50)
TERRACOTTA = (196, 101, 74)

CANVAS = 1024
MARK_SCALE = 5.62  # ~55% safe zone
MARK_CENTER = (50.0, 43.0)
STROKE = 4 * MARK_SCALE
DOT_RADIUS = 2 * MARK_SCALE


def to_canvas(x: float, y: float) -> tuple[float, float]:
    cx, cy = CANVAS / 2, CANVAS / 2
    mx, my = MARK_CENTER
    return cx + (x - mx) * MARK_SCALE, cy + (y - my) * MARK_SCALE


def sample_quadratic(
    p0: tuple[float, float],
    p1: tuple[float, float],
    p2: tuple[float, float],
    steps: int = 40,
) -> list[tuple[float, float]]:
    points: list[tuple[float, float]] = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0]
        y = u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1]
        points.append((x, y))
    return points


def draw_threshold(draw: ImageDraw.ImageDraw) -> None:
    left = to_canvas(32, 28)
    left_base = to_canvas(32, 72)
    right = to_canvas(64, 28)
    right_base = to_canvas(64, 72)

    draw.line([left_base, left], fill=MIDNIGHT_BLUE, width=int(STROKE))
    draw.line([right_base, right], fill=MIDNIGHT_BLUE, width=int(STROKE))

    arch = sample_quadratic((36, 28), (50, 16), (64, 28))
    canvas_arch = [to_canvas(x, y) for x, y in arch]
    draw.line(canvas_arch, fill=MIDNIGHT_BLUE, width=int(STROKE))

    dot_center = to_canvas(50, 14)
    bbox = [
        dot_center[0] - DOT_RADIUS,
        dot_center[1] - DOT_RADIUS,
        dot_center[0] + DOT_RADIUS,
        dot_center[1] + DOT_RADIUS,
    ]
    draw.ellipse(bbox, fill=TERRACOTTA)


def main() -> None:
    output = Path(__file__).resolve().parents[1] / "icons" / "atlas-app-icon-1024.png"
    image = Image.new("RGB", (CANVAS, CANVAS), WARM_OFF_WHITE)
    draw = ImageDraw.Draw(image)
    draw_threshold(draw)
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output, format="PNG", optimize=True)
    print(f"Wrote {output}")


if __name__ == "__main__":
    main()
