#!/usr/bin/env python3
"""Genera el icono de la aplicación.

Reproduce en Pillow el mismo dibujo que `BrandMarkPainter` pinta en Flutter:
un histograma acampanado, la curva de distribución encima y la línea de la
media punteada. Que el icono y la marca de la app salgan del mismo diseño no es
casualidad: el usuario debe reconocer la app por el símbolo, no por el texto.

Salidas:
  assets/icon/app_icon.png             1024×1024, con fondo (Android/iOS)
  assets/icon/app_icon_foreground.png  1024×1024, transparente y con margen
                                       seguro para el icono adaptativo Android
"""
import math
from PIL import Image, ImageDraw

NAVY = (14, 42, 71, 255)
PRIMARY_LIGHT = (62, 134, 184, 255)
TEAL = (42, 157, 143, 255)
ORANGE = (231, 111, 81, 255)
AMBER = (233, 162, 59, 255)
WHITE = (255, 255, 255, 255)

HEIGHTS = [0.18, 0.42, 0.74, 1.00, 0.82, 0.50, 0.26]


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(4))


def rounded_top_rect(draw, box, radius, fill):
    x0, y0, x1, y1 = box
    r = min(radius, (x1 - x0) / 2, (y1 - y0))
    if r <= 0:
        draw.rectangle(box, fill=fill)
        return
    draw.rectangle((x0, y0 + r, x1, y1), fill=fill)
    draw.pieslice((x0, y0, x0 + 2 * r, y0 + 2 * r), 180, 270, fill=fill)
    draw.pieslice((x1 - 2 * r, y0, x1, y0 + 2 * r), 270, 360, fill=fill)
    draw.rectangle((x0 + r, y0, x1 - r, y0 + r), fill=fill)


def draw_mark(size, background, padding):
    """Dibuja la marca con supermuestreo ×4 para bordes limpios."""
    scale = 4
    s = size * scale
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    if background is not None:
        radius = int(s * 0.22)
        d.rounded_rectangle((0, 0, s - 1, s - 1), radius=radius, fill=background)

    pad = s * padding
    top = pad + s * 0.06
    left, right, bottom = pad, s - pad, s - pad
    plot_w = right - left
    plot_h = bottom - top

    bar_w = plot_w / len(HEIGHTS)
    for i, h in enumerate(HEIGHTS):
        bh = plot_h * h * 0.86
        x0 = left + bar_w * i + bar_w * 0.06
        x1 = x0 + bar_w * 0.88
        if i == 3:
            color = ORANGE
        else:
            color = lerp(PRIMARY_LIGHT, TEAL, i / (len(HEIGHTS) - 1))
        color = (color[0], color[1], color[2], 255)
        rounded_top_rect(d, (x0, bottom - bh, x1, bottom), s * 0.022, color)

    # Curva de distribución.
    pts = []
    steps = 240
    for i in range(steps + 1):
        t = i / steps
        x = left + plot_w * t
        z = (t - 0.47) / 0.20
        y = bottom - plot_h * 0.94 * math.exp(-0.5 * z * z)
        pts.append((x, y))
    d.line(pts, fill=WHITE, width=int(s * 0.030), joint="curve")
    # Extremos redondeados.
    r = s * 0.015
    for p in (pts[0], pts[-1]):
        d.ellipse((p[0] - r, p[1] - r, p[0] + r, p[1] + r), fill=WHITE)

    # Línea de la media, punteada.
    mean_x = left + plot_w * 0.47
    y = top
    w = s * 0.024
    while y < bottom:
        end = min(y + s * 0.055, bottom)
        d.line([(mean_x, y), (mean_x, end)], fill=AMBER, width=int(w))
        y = end + s * 0.04

    # Eje base.
    d.line([(left, bottom), (right, bottom)],
           fill=(255, 255, 255, 217), width=int(s * 0.03))

    return img.resize((size, size), Image.LANCZOS)


def main():
    draw_mark(1024, NAVY, 0.14).save("assets/icon/app_icon.png")
    # El icono adaptativo de Android recorta hasta el 25 % del borde: el
    # primer plano lleva más margen para que nada quede fuera de la máscara.
    draw_mark(1024, None, 0.26).save("assets/icon/app_icon_foreground.png")
    # Vista previa para la documentación.
    draw_mark(256, NAVY, 0.14).save("docs/icono.png")
    print("Iconos generados en assets/icon/")


if __name__ == "__main__":
    main()
