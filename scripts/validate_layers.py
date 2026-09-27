#!/usr/bin/env python3
"""Check the four-layer delivery contract and both Xcode target inputs."""
from pathlib import Path
import hashlib
import json
import plistlib
import yaml
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
NAMES = ("character_base", "cloak", "hair", "rain")


def main():
    manifest = json.loads((ROOT / "Assets/Layers/manifest.json").read_text())
    assert manifest["canvas"] == [1024, 1024]
    assert manifest["zOrder"] == list(NAMES)
    for name in NAMES:
        asset = ROOT / f"Assets/Layers/{name}.png"
        with Image.open(asset) as image:
            assert image.mode == "RGBA", f"{name}: missing RGBA"
            assert image.size == (1024, 1024), f"{name}: canvas mismatch"
            alpha = image.getchannel("A")
            assert alpha.getextrema() == (0, 255), f"{name}: missing real transparency/solid ink"
            for edge in ((0, 0, 1024, 1), (0, 1023, 1024, 1024), (0, 0, 1, 1024), (1023, 0, 1024, 1024)):
                assert alpha.crop(edge).getbbox() is None, f"{name}: artwork/background reaches canvas border"
            coverage = sum(1 for value in alpha.getdata() if value > 0) / (1024 * 1024)
            assert 0.005 < coverage < 0.6, f"{name}: empty asset or suspicious rectangular matte"
            assert all((r, g, b) == (255, 255, 255) for r, g, b, a in image.getdata() if a > 0), f"{name}: template pixels must be white"
        folder = ROOT / f"Shared/LayerAssets.xcassets/{name}.imageset"
        metadata = json.loads((folder / "Contents.json").read_text())
        assert metadata["images"][0]["filename"] == f"{name}.png"
        assert metadata["properties"]["template-rendering-intent"] == "template"
        assert (folder / f"{name}.png").read_bytes() == asset.read_bytes(), f"{name}: source and bundled copy differ"
        print(f"PASS {name}: RGBA, aligned canvas, clear border, {coverage:.1%} artwork; SHA256 {hashlib.sha256(asset.read_bytes()).hexdigest()}")

    project = yaml.safe_load((ROOT / "project.yml").read_text())
    assert project["options"]["deploymentTarget"]["iOS"] == "17.0"
    targets = project["targets"]
    assert targets["Wigy"]["dependencies"] == [{"target": "WigyWidgets", "embed": True}]
    for name, target in targets.items():
        assert "Shared" in target["sources"]
        for source in target["sources"]:
            assert (ROOT / source).exists()
        assert "entitlements" not in target
        with open(ROOT / target["settings"]["base"]["INFOPLIST_FILE"], "rb") as file:
            info = plistlib.load(file)
        assert info["CFBundleIdentifier"] == "$(PRODUCT_BUNDLE_IDENTIFIER)"
        if name == "WigyWidgets":
            assert info["NSExtension"]["NSExtensionPointIdentifier"] == "com.apple.widgetkit-extension"
        else:
            assert info["CFBundlePackageType"] == "APPL"
    app_id = targets["Wigy"]["settings"]["base"]["PRODUCT_BUNDLE_IDENTIFIER"]
    extension_id = targets["WigyWidgets"]["settings"]["base"]["PRODUCT_BUNDLE_IDENTIFIER"]
    assert extension_id.startswith(app_id + ".")
    assert "Widget" not in targets["Wigy"]["sources"], "Widget intent must stay in the extension sandbox"
    with Image.open(ROOT / "App/Assets.xcassets/AppIcon.appiconset/AppIcon.png") as icon:
        assert icon.size == (1024, 1024) and icon.mode == "RGB"
    print("PASS Xcode target membership, bundle IDs, extension embedding, plists, and opaque app icon")


if __name__ == "__main__":
    main()
