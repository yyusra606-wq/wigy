#!/usr/bin/env python3
"""Make aligned prototype cutouts from the supplied sheet (not AI generation).

The source contains alpha but also halo pixels and unrelated adjacent effects.
Semantic masks split the first figure; white template ink uses luminance as
alpha so its dark costume details remain negative space in monochrome widgets.
"""
from pathlib import Path
from collections import deque
import json
from PIL import Image, ImageDraw, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
CANVAS = (1024, 1024)
NAMES = ("character_base", "cloak", "hair", "rain")


def polygon(points):
    mask = Image.new("L", (1536, 1024))
    ImageDraw.Draw(mask).polygon(points, fill=255)
    return mask


def template_ink(source):
    alpha = source.getchannel("A").point(lambda p: 0 if p < 32 else min(255, round((p - 32) * 255 / 222)))
    brightness = source.convert("L").point(lambda p: max(0, min(255, round((p - 85) * 255 / 155))))
    return ImageChops.multiply(alpha, brightness)


def aligned_figure(ink, mask):
    alpha = ImageChops.multiply(ink, mask).crop((0, 60, 300, 600))
    alpha = alpha.resize((480, 864), Image.Resampling.LANCZOS)
    canvas = Image.new("L", CANVAS)
    canvas.paste(alpha, (80, 80))
    result = Image.new("RGBA", CANVAS, (255, 255, 255, 0))
    result.putalpha(canvas)
    return result


def rain_cutout(ink):
    crop = ink.crop((930, 580, 1125, 984))
    width, height = crop.size
    points = crop.load()
    visited = set()
    clean = Image.new("L", crop.size)
    target = clean.load()
    # Retain long, narrow connected streaks. Discard floating specks and glows.
    for y in range(height):
        for x in range(width):
            if (x, y) in visited or points[x, y] < 45:
                continue
            queue = deque([(x, y)])
            visited.add((x, y))
            component = []
            while queue:
                px, py = queue.popleft()
                component.append((px, py))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = px + dx, py + dy
                        if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in visited and points[nx, ny] >= 45:
                            visited.add((nx, ny))
                            queue.append((nx, ny))
            xs, ys = zip(*component)
            span_x, span_y = max(xs) - min(xs) + 1, max(ys) - min(ys) + 1
            if span_y >= 12 and span_y > span_x * 2 and len(component) >= 15:
                for px, py in component:
                    target[px, py] = points[px, py]
    clean = clean.resize((390, 808), Image.Resampling.LANCZOS)
    canvas = Image.new("L", CANVAS)
    canvas.paste(clean, (80, 108))
    canvas.paste(clean, (560, 108))
    result = Image.new("RGBA", CANVAS, (255, 255, 255, 0))
    result.putalpha(canvas)
    return result


def main():
    source = Image.open(ROOT / "Reference/layer-sheet.png").convert("RGBA")
    if source.size != (1536, 1024):
        raise ValueError("These masks are specific to the supplied 1536x1024 sheet")
    ink = template_ink(source)
    body = polygon([(140, 112), (165, 116), (180, 153), (191, 170), (202, 196),
                    (214, 222), (219, 271), (228, 314), (229, 338), (216, 347),
                    (208, 329), (198, 278), (187, 245), (191, 302), (186, 357),
                    (191, 416), (208, 484), (224, 565), (218, 583), (193, 586),
                    (179, 565), (158, 469), (146, 418), (136, 457), (108, 523),
                    (102, 569), (83, 584), (49, 586), (56, 568), (72, 549),
                    (87, 476), (112, 394), (120, 337), (123, 274), (111, 222),
                    (99, 238), (92, 274), (84, 313), (85, 333), (76, 348),
                    (65, 337), (66, 317), (71, 283), (78, 245), (86, 215),
                    (99, 183), (121, 168), (130, 152)])
    # Hair shares the head anchor with the body. It contains no face or torso.
    hair = polygon([(105, 132), (116, 108), (121, 94), (132, 89), (139, 78),
                    (144, 87), (155, 79), (152, 86), (168, 82), (179, 94),
                    (191, 100), (185, 111), (194, 126), (187, 126), (190, 147),
                    (202, 170), (231, 196), (217, 191), (203, 184), (211, 202),
                    (192, 189), (183, 176), (176, 165), (170, 151), (164, 140),
                    (165, 127), (157, 135), (150, 121), (144, 124), (140, 115),
                    (137, 132), (128, 146), (124, 165), (111, 185), (89, 205),
                    (75, 227), (80, 208), (88, 191), (104, 169), (119, 140)])
    # Use the sheet's separate flowing cape study, anchored at the right shoulder.
    # Its head/neck study is excluded, so this layer contains only loose fabric.
    coat = polygon([(923, 190), (950, 184), (985, 194), (1027, 201),
                    (1075, 211), (1118, 225), (1160, 244), (1194, 270),
                    (1218, 308), (1190, 289), (1183, 310), (1201, 351),
                    (1210, 402), (1191, 372), (1177, 360), (1182, 408),
                    (1203, 451), (1207, 477), (1180, 450), (1163, 448),
                    (1180, 488), (1206, 540), (1176, 512), (1152, 496),
                    (1164, 539), (1160, 556), (1133, 511), (1112, 492),
                    (1076, 454), (1054, 432), (1041, 448), (1025, 471),
                    (1008, 510), (1000, 547), (989, 535), (981, 509),
                    (964, 478), (940, 463), (918, 439), (917, 390),
                    (924, 345), (932, 295), (923, 258), (918, 218)])
    cape_alpha = ImageChops.multiply(ink, coat).crop((900, 175, 1230, 565))
    cape_alpha = cape_alpha.resize((528, 624), Image.Resampling.LANCZOS)
    cape_canvas = Image.new("L", CANVAS)
    cape_canvas.paste(cape_alpha, (343, 256))
    cape = Image.new("RGBA", CANVAS, (255, 255, 255, 0))
    cape.putalpha(cape_canvas)
    body = ImageChops.subtract(body, hair)
    assets = {"character_base": aligned_figure(ink, body),
              "cloak": cape,
              "hair": aligned_figure(ink, hair),
              "rain": rain_cutout(ink)}
    out = ROOT / "Assets/Layers"
    out.mkdir(parents=True, exist_ok=True)
    catalog = ROOT / "Shared/LayerAssets.xcassets"
    catalog.mkdir(parents=True, exist_ok=True)
    (catalog / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    for name, image in assets.items():
        image.save(out / f"{name}.png", optimize=True)
        folder = catalog / f"{name}.imageset"
        folder.mkdir(exist_ok=True)
        image.save(folder / f"{name}.png", optimize=True)
        (folder / "Contents.json").write_text(json.dumps({
            "images": [{"filename": f"{name}.png", "idiom": "universal"}],
            "info": {"author": "xcode", "version": 1},
            "properties": {"template-rendering-intent": "template"}}, indent=2) + "\n")
    manifest = {"canvas": list(CANVAS), "origin": "top-left", "zOrder": list(NAMES),
                "provenance": "Extracted from the user-provided sheet using semantic masks; not newly AI-generated.",
                "source": "Reference/layer-sheet.png",
                "figureSourceRect": [0, 60, 300, 600], "figureScale": 1.6, "figureOffset": [80, 80],
                "cloakSourceRect": [900, 175, 1230, 565], "cloakSize": [528, 624], "cloakOffset": [343, 256],
                "limitations": ["Occluded anatomy has not been generatively reconstructed.",
                                "Inspect the cloak seams during motion before replacing these prototype cutouts with final artwork."]}
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("Wrote four aligned transparent PNG layers and their asset catalog.")


if __name__ == "__main__":
    main()
