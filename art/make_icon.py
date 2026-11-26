"""Draws the Nickname Forever icon: two arrows swapping on a dark tile.
Top arrow (blue, the real name) points right; bottom arrow (WoW gold, the
nickname) points left. Rendered at 4x and downsampled for smooth edges.
Outputs: art/icon-512.png, art/icon-400.png (CurseForge) and
NicknameForever/Media/Icon.tga (64x64, in-game).
"""
import os
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
S = 2048                      # working size
u = S / 1024                  # design units are on a 1024 grid

def P(*xy): return [v * u for v in xy]

def vgrad(size, top, bottom):
    w, h = size
    g = Image.new("RGBA", size)
    d = ImageDraw.Draw(g)
    for y in range(h):
        t = y / max(1, h - 1)
        d.line([(0, y), (w, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,))
    return g

def arrow_mask(y, right, shaft_h=104, head_h=300, x0=210, x1=814, head_len=200):
    """Mask of a horizontal arrow on the 1024 grid; tip at x1 (right) or x0 (left).
    The shaft runs well under the head so the join has no seam."""
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)
    r = shaft_h / 2
    if right:
        tip, base, tail = x1, x1 - head_len, x0
        d.rounded_rectangle(P(tail, y - r, base + head_len / 2, y + r), radius=r * u, fill=255)
    else:
        tip, base, tail = x0, x0 + head_len, x1
        d.rounded_rectangle(P(base - head_len / 2, y - r, tail, y + r), radius=r * u, fill=255)
    d.polygon(P(tip, y, base, y - head_h / 2, base, y + head_h / 2), fill=255)
    return m

def colorize(mask, top, bottom, y0, y1):
    g = vgrad((S, S), (0, 0, 0), (0, 0, 0))
    band = vgrad((S, int((y1 - y0) * u)), top, bottom)
    g.paste(band, (0, int(y0 * u)))
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.paste(g, (0, 0), mask)
    return out

# --- tile -------------------------------------------------------------------
tile_mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(tile_mask).rounded_rectangle(P(16, 16, 1008, 1008), radius=190 * u, fill=255)
bg = vgrad((S, S), (30, 46, 78), (9, 15, 30))
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
img.paste(bg, (0, 0), tile_mask)

# soft glow behind the arrows
glow = Image.new("L", (S, S), 0)
ImageDraw.Draw(glow).ellipse(P(150, 220, 874, 804), fill=70)
glow = glow.filter(ImageFilter.GaussianBlur(120 * u))
img.paste(Image.new("RGBA", (S, S), (102, 204, 255, 255)), (0, 0), Image.composite(glow, Image.new("L", (S, S), 0), tile_mask))

# border: thin blue ring inside the tile edge
ring = Image.new("L", (S, S), 0)
rd = ImageDraw.Draw(ring)
rd.rounded_rectangle(P(16, 16, 1008, 1008), radius=190 * u, fill=255)
rd.rounded_rectangle(P(40, 40, 984, 984), radius=168 * u, fill=0)
img.paste(Image.new("RGBA", (S, S), (77, 153, 230, 255)), (0, 0), ring.point(lambda v: v * 200 // 255))

# --- arrows -----------------------------------------------------------------
TOP_Y, BOT_Y = 372, 652
top = arrow_mask(TOP_Y, right=True)
bot = arrow_mask(BOT_Y, right=False)

# drop shadows
for m in (top, bot):
    sh = m.filter(ImageFilter.GaussianBlur(18 * u)).point(lambda v: v * 150 // 255)
    sh = sh.transform(sh.size, Image.AFFINE, (1, 0, 0, 0, 1, -14 * u))
    img.paste(Image.new("RGBA", (S, S), (0, 0, 0, 255)), (0, 0), sh)

img.alpha_composite(colorize(top, (150, 222, 255), (64, 170, 240), TOP_Y - 150, TOP_Y + 150))
img.alpha_composite(colorize(bot, (255, 226, 92), (240, 176, 0), BOT_Y - 150, BOT_Y + 150))

# --- outputs ----------------------------------------------------------------
img.resize((512, 512), Image.LANCZOS).save(os.path.join(HERE, "icon-512.png"))
img.resize((400, 400), Image.LANCZOS).save(os.path.join(HERE, "icon-400.png"))
small = img.resize((64, 64), Image.LANCZOS)
small.save(os.path.join(ROOT, "NicknameForever", "Media", "Icon.tga"))
small.save(os.path.join(HERE, "icon-64-preview.png"))
print("done")
