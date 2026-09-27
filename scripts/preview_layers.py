#!/usr/bin/env python3
"""Export a transparency/registration inspection board, not a widget screenshot."""
from pathlib import Path
import argparse
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, default=root / 'build/previews')
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
size = (1024, 1024)
board = Image.new('RGBA', size, (29, 34, 44, 255))
draw = ImageDraw.Draw(board)
for y in range(0, 1024, 32):
    for x in range(0, 1024, 32):
        if (x // 32 + y // 32) % 2:
            draw.rectangle((x, y, x + 31, y + 31), fill=(41, 47, 59, 255))
assets = {name: Image.open(root / f'Assets/Layers/{name}.png').convert('RGBA')
          for name in ('character_base', 'cloak', 'hair', 'rain')}
composite = Image.new('RGBA', size)
for name, image in assets.items():
    layer = image.copy()
    if name == 'rain':
        layer.putalpha(layer.getchannel('A').point(lambda p: round(p * .24)))
    composite.alpha_composite(layer)
composite.save(args.output / 'reconstructed-transparent.png', optimize=True)
tiles = []
for name, image in assets.items():
    tile = board.copy()
    tile.alpha_composite(image)
    tiles.append((name + '.png', tile))
for label, background, ink in [('Stacked / dark', (18, 23, 33, 255), (255, 255, 255, 0)),
                               ('Monochrome / light', (237, 240, 246, 255), (25, 30, 40, 0))]:
    tile = Image.new('RGBA', size, background)
    layer = Image.new('RGBA', size, ink)
    layer.putalpha(composite.getchannel('A'))
    tile.alpha_composite(layer)
    tiles.append((label, tile))
sheet = Image.new('RGB', (1200, 904), (13, 17, 26))
try:
    font = ImageFont.truetype('DejaVuSans.ttf', 17)
except OSError:
    font = ImageFont.load_default()
for index, (label, tile) in enumerate(tiles):
    x, y = (index % 3) * 400, (index // 3) * 452
    ImageDraw.Draw(sheet).text((x + 16, y + 15), label, fill='white', font=font)
    sheet.paste(tile.resize((400, 400), Image.Resampling.LANCZOS), (x, y + 52))
sheet.save(args.output / 'layer-inspection.png', optimize=True)
print('Wrote layer-inspection.png and reconstructed-transparent.png')
