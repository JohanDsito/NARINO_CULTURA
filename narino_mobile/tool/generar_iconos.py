"""Íconos de la app con la marca de Nariño Cultura: montaña blanca sobre el degradado naranja → magenta.

Uso (desde narino_mobile): python tool/generar_iconos.py assets/branding   (requiere Pillow)
Después: dart run flutter_launcher_icons && dart run flutter_native_splash:create
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(sys.argv[1])
OUT.mkdir(parents=True, exist_ok=True)
SIZE = 1024
SS = 4  # supermuestreo para bordes suaves
NARANJA = (255, 102, 0)
MAGENTA = (229, 0, 80)
BLANCO = (255, 255, 255, 255)

# Montaña de lucide (24×24, trazo de 2): m8 3 4 8 5-5 5 15H2L8 3z
MONTANA = [(8, 3), (12, 11), (17, 6), (22, 21), (2, 21), (8, 3), (12, 11)]


def degradado(size):
    """Degradado diagonal naranja (arriba a la izquierda) → magenta (abajo a la derecha)."""
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(NARANJA, MAGENTA))
    return img


def montana(size, escala):
    """Capa transparente con la montaña blanca centrada; `escala` es la fracción del lado que ocupa el ícono de 24."""
    big = size * SS
    capa = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    lado = big * escala
    unidad = lado / 24
    off = (big - lado) / 2
    pts = [(off + x * unidad, off + y * unidad + unidad * 0.5) for x, y in MONTANA]
    ImageDraw.Draw(capa).line(pts, fill=BLANCO, width=round(2.2 * unidad), joint="curve")
    return capa.resize((size, size), Image.LANCZOS)


def redondeado(img, radio):
    mascara = Image.new("L", (img.width * SS, img.height * SS), 0)
    ImageDraw.Draw(mascara).rounded_rectangle([0, 0, mascara.width - 1, mascara.height - 1], radius=radio * SS, fill=255)
    mascara = mascara.resize(img.size, Image.LANCZOS)
    out = img.convert("RGBA")
    out.putalpha(mascara)
    return out


fondo = degradado(SIZE)

# Ícono completo (iOS y Android anterior a 8): cuadrado sin transparencia; cada sistema aplica su máscara
icono = fondo.convert("RGBA")
icono.alpha_composite(montana(SIZE, 0.58))
icono.convert("RGB").save(OUT / "icono.png")

# Ícono adaptable (Android 8+): fondo y frente por separado; el frente dentro de la zona segura (~61 %)
fondo.save(OUT / "icono_fondo.png")
# flutter_launcher_icons agrega un margen del 16 %: con 0.60 la montaña queda ~41 % del ícono, dentro de la zona segura
montana(SIZE, 0.60).save(OUT / "icono_frente.png")
montana(SIZE, 0.60).save(OUT / "icono_monocromo.png")  # Android 13: íconos temáticos
# Android 12 recorta el ícono de la pantalla de inicio en un círculo (2/3 del lado): más pequeño para no cortar esquinas
montana(SIZE, 0.42).save(OUT / "splash_android12.png")

# Pantalla de inicio: la marca como cuadrado redondeado (radio 22 % como las tarjetas de la app)
splash = redondeado(icono.convert("RGB"), round(SIZE * 0.22)).resize((512, 512), Image.LANCZOS)
splash.save(OUT / "splash.png")

print("íconos generados en", OUT)
