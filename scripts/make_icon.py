#!/usr/bin/env python3
"""Create the app icon from the same transparent layers; this is UI, not scene art."""
from pathlib import Path
import json
from PIL import Image

root = Path(__file__).resolve().parents[1]
folder = root / 'App/Assets.xcassets/AppIcon.appiconset'
folder.mkdir(parents=True, exist_ok=True)
base = Image.new('RGBA', (1024, 1024))
for name in ['character_base', 'cloak', 'hair']:
    base.alpha_composite(Image.open(root / f'Assets/Layers/{name}.png'))
art = base.crop((145, 100, 930, 930))
art.thumbnail((790, 840), Image.Resampling.LANCZOS)
icon = Image.new('RGBA', (1024, 1024), (14, 22, 38, 255))
icon.alpha_composite(art, ((1024 - art.width) // 2, (1024 - art.height) // 2))
icon.convert('RGB').save(folder / 'AppIcon.png', optimize=True)
(folder.parent / 'Contents.json').write_text(json.dumps({'info': {'author': 'xcode', 'version': 1}}, indent=2) + '\n')
(folder / 'Contents.json').write_text(json.dumps({'images': [{'filename': 'AppIcon.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}], 'info': {'author': 'xcode', 'version': 1}}, indent=2) + '\n')
print('Wrote opaque 1024x1024 app icon.')
