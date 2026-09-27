# Prototype verification

## Completed locally

- Four actual RGBA PNGs: shared 1024 × 1024 canvas, alpha-zero borders, nonempty
  artwork, no full-canvas matte, matching source/catalog copies.
- Inspected the separated layers and their reconstructed composition on dark,
  light, and checkerboard backgrounds. The preview board is an asset inspection,
  not a screenshot of an iOS widget.
- Parsed all Swift files with a Swift grammar parser. This checks syntax only;
  it does not resolve SwiftUI/WidgetKit symbols or perform an Xcode build.
- Validated Xcode target membership, extension embedding declaration, bundle IDs,
  plist structure, and app icon dimensions/opacity.
- Linted the GitHub Actions workflow with actionlint and checked build shell syntax.
- Confirmed the IPA validator rejects a source ZIP renamed with an `.ipa` suffix.
- Verified the XcodeGen 2.44.1 release archive against its published SHA-256.

## Still required

- Successful macOS Xcode build and structural validation of the resulting IPA.
- SideStore signing/installation with the app extension preserved.
- Actual widget motion in all declared families on iPhone/iPad, including
  Reduce Motion, Always On, and monochrome rendering.
- Art review of the extraction's scalp/shoulder seams in motion. Hidden anatomy
  has not been reconstructed by an image-generation model.

The code-review command reported that CodeRabbit review is disabled for this task;
no automated review findings were produced. The local host is Linux and has no
Xcode or iOS SDK. A valid IPA must come from the provided macOS workflow or a Mac.

## Remote build blocker — 2026-09-27

The connected GitHub App lacks `workflows` permission. The workflow YAML is
therefore supplied separately as `build-ipa.txt` in task Outputs and excluded
from the repository commit. To run it, add its contents as
`.github/workflows/build-ipa.yml` using a GitHub account with workflow-write
permission, then run the macOS build. No Apple signing secret is required.
**No `wigy.ipa` has been produced yet.**
