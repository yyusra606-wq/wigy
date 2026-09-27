#!/usr/bin/env python3
"""Reject source ZIPs, simulator bundles, and IPAs missing the widget extension."""
import argparse
import plistlib
import struct
from zipfile import ZipFile


def validate(path):
    with ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise ValueError("Corrupt ZIP member")
        root = "Payload/Wigy.app/"
        app = plistlib.loads(archive.read(root + "Info.plist"))
        widget_root = root + "PlugIns/WigyWidgets.appex/"
        widget = plistlib.loads(archive.read(widget_root + "Info.plist"))
        if app["CFBundlePackageType"] != "APPL":
            raise ValueError("Main bundle is not an iOS app")
        if not widget["CFBundleIdentifier"].startswith(app["CFBundleIdentifier"] + "."):
            raise ValueError("Widget bundle ID must be nested under the app ID")
        if widget.get("UIAppFonts") != ["WigySceneFrames.ttf"]:
            raise ValueError("Timer scene font is not registered in the widget")
        if not archive.read(widget_root + "WigySceneFrames.ttf"):
            raise ValueError("Timer scene font is missing from the widget")
        if widget["NSExtension"]["NSExtensionPointIdentifier"] != "com.apple.widgetkit-extension":
            raise ValueError("Missing WidgetKit extension declaration")
        for prefix, info in ((root, app), (widget_root, widget)):
            if "iPhoneOS" not in info.get("CFBundleSupportedPlatforms", []):
                raise ValueError("This must be an iPhoneOS device build, not a simulator build")
            name = info["CFBundleExecutable"]
            binary = archive.read(prefix + name)
            if len(binary) < 32 or struct.unpack_from("<II", binary) != (0xFEEDFACF, 0x0100000C):
                raise ValueError("Expected a compiled arm64 Mach-O executable")
            if (archive.getinfo(prefix + name).external_attr >> 16) & 0o111 == 0:
                raise ValueError("Executable file permissions are missing")
            if not archive.read(prefix + "Assets.car"):
                raise ValueError("Compiled layer assets are missing")
    print("PASS: device app, arm64 executables, compiled assets, and embedded WidgetKit extension")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ipa")
    validate(parser.parse_args().ipa)
