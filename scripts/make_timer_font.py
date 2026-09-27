#!/usr/bin/env python3
"""Generate monochrome scene glyphs for the experimental timer widget.

Digits 6/5, 4/3, and 2/1 are three two-second scene phases. Zero and
punctuation are empty, so 0:06 displays only the six glyph and 0:00 ends blank.
"""
from pathlib import Path
from PIL import Image, ImageChops
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'Widget/Resources/WigySceneFrames.ttf'
NAMES = ('character_base', 'cloak', 'hair', 'rain')
SIZE = 128
UPM = 1024


def shifted(image, dx, dy):
    result = Image.new('L', image.size)
    result.paste(image, (dx, dy))
    return result


def scene(phase):
    layers = {name: Image.open(ROOT / f'Shared/LayerAssets.xcassets/accessory_{name}.imageset/accessory_{name}.png').getchannel('A') for name in NAMES}
    offsets = {
        0: {'cloak': (-5, 0), 'hair': (-3, -2), 'rain': (0, -12)},
        1: {'cloak': (0, 0), 'hair': (0, 0), 'rain': (0, 0)},
        2: {'cloak': (5, 0), 'hair': (3, 2), 'rain': (0, 12)},
    }[phase]
    mask = Image.new('L', (256, 256))
    for name in NAMES:
        part = layers[name]
        if name in offsets:
            part = shifted(part, *offsets[name])
        if name == 'rain':
            part = part.point(lambda value: round(value * 0.36))
        mask = ImageChops.lighter(mask, part)
    return mask.resize((SIZE, SIZE), Image.Resampling.LANCZOS)


def glyph_for(mask):
    pen = TTGlyphPen(None)
    if mask is None:
        return pen.glyph()
    pixels = mask.load()
    # Every horizontal run becomes a tiny vector rectangle. At 128px the
    # outlines retain the transparent silhouette without embedding a bitmap.
    for y in range(SIZE):
        x = 0
        while x < SIZE:
            if pixels[x, y] < 96:
                x += 1
                continue
            begin = x
            while x < SIZE and pixels[x, y] >= 96:
                x += 1
            left, right = begin * 8, x * 8
            bottom, top = (SIZE - 1 - y) * 8, (SIZE - y) * 8
            pen.moveTo((left, bottom))
            pen.lineTo((right, bottom))
            pen.lineTo((right, top))
            pen.lineTo((left, top))
            pen.closePath()
    return pen.glyph()


def main():
    order = ['.notdef', 'space', 'colon', 'minus'] + [f'digit{n}' for n in range(10)]
    glyphs = {name: glyph_for(None) for name in order}
    for digit in range(1, 7):
        phase = (6 - digit) // 2
        glyphs[f'digit{digit}'] = glyph_for(scene(phase))
    cmap = {ord(' '): 'space', ord(':'): 'colon', ord('-'): 'minus'}
    cmap.update({ord(str(n)): f'digit{n}' for n in range(10)})
    fb = FontBuilder(UPM, isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap(cmap)
    fb.setupGlyf(glyphs)
    fb.setupHorizontalMetrics({name: (UPM if name in {f'digit{n}' for n in range(1, 7)} else 0, 0) for name in order})
    fb.setupHorizontalHeader(ascent=UPM, descent=0)
    fb.setupNameTable({'familyName': 'Wigy Scene Frames', 'styleName': 'Regular',
                       'uniqueFontIdentifier': 'WigySceneFrames-Regular-1',
                       'fullName': 'Wigy Scene Frames Regular',
                       'psName': 'WigySceneFrames-Regular', 'version': 'Version 1.0'})
    fb.setupOS2(sTypoAscender=UPM, sTypoDescender=0, usWinAscent=UPM, usWinDescent=0)
    fb.setupPost()
    fb.setupMaxp()
    fb.setupHead(created=2082844800, modified=2082844800)
    fb.font.recalcTimestamp = False
    OUT.parent.mkdir(parents=True, exist_ok=True)
    fb.save(OUT)
    print(f'Wrote {OUT.relative_to(ROOT)} ({OUT.stat().st_size} bytes)')


if __name__ == '__main__':
    main()
