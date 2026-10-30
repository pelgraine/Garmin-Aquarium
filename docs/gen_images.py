#!/usr/bin/env python3
# Makes the two PNGs the Garmin aquarium app needs:
#   grid.png          240x240 overlay: black at the four corners of every 3x3
#                     cell, transparent elsewhere. Drawn over the tank in one
#                     call, it turns smooth shapes into the CYD's plus-shaped
#                     dots (the CYD dot renderer lights 5 of the 9 pixels).
#   launcher_icon.png 40x40 app icon (original drawing: a small fish).
# Usage: python3 -I gen_images.py <output dir>
import sys
from PIL import Image, ImageDraw

out = sys.argv[1]

W = 240
grid = Image.new("RGBA", (W, W), (0, 0, 0, 0))
px = grid.load()
for cy in range(0, W, 3):
    for cx in range(0, W, 3):
        for dx, dy in ((0, 0), (2, 0), (0, 2), (2, 2)):
            px[cx + dx, cy + dy] = (0, 0, 0, 255)
grid.save(out + "/grid.png")

icon = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
d = ImageDraw.Draw(icon)
d.ellipse((0, 0, 39, 39), fill=(6, 30, 60, 255))
# body, tail, eye
d.ellipse((9, 14, 27, 26), fill=(255, 140, 30, 255))
d.polygon([(26, 20), (34, 13), (34, 27)], fill=(255, 140, 30, 255))
d.ellipse((13, 17, 16, 20), fill=(10, 10, 20, 255))
# two white bands like the CYD clownfish
d.rectangle((18, 14, 20, 26), fill=(245, 245, 250, 255))
d.rectangle((23, 15, 24, 25), fill=(245, 245, 250, 255))
icon.save(out + "/launcher_icon.png")
print("wrote grid.png and launcher_icon.png")
