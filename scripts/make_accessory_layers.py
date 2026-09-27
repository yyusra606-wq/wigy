#!/usr/bin/env python3
"""Prepare aligned, small alpha layers for the Lock Screen renderer."""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CROP = (170, 92, 590, 472)
for name in ('character_base', 'cloak', 'hair', 'rain'):
    with Image.open(ROOT / f'Assets/Layers/{name}.png') as source:
        portrait = source.crop(CROP).resize((256, 232), Image.Resampling.LANCZOS)
    canvas = Image.new('RGBA', (256, 256))
    canvas.alpha_composite(portrait, (0, 12))
    folder = ROOT / f'Shared/LayerAssets.xcassets/accessory_{name}.imageset'
    folder.mkdir(parents=True, exist_ok=True)
    canvas.save(folder / f'accessory_{name}.png', optimize=True)
    (folder / 'Contents.json').write_text(json.dumps({
        'images': [{'filename': f'accessory_{name}.png', 'idiom': 'universal'}],
        'info': {'author': 'xcode', 'version': 1},
        'properties': {'template-rendering-intent': 'template'}
    }, indent=2) + '\n')
print('Prepared four aligned 256px accessory layers')
