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

## Device report and revision — 2026-09-27

The first IPA compiled successfully in GitHub Actions run 36325928280; its ARM64
app, embedded widget, assets, and ZIP integrity passed structural validation.
The user then reported a white Lock Screen tile and static Home Screen artwork.
That device report means widget appearance and motion are not validated.

Version 0.1.1 uses four aligned 256px portrait layers on the Lock Screen, removes
its clear background rectangle, makes the entire scene tappable, and requests an
explicit timeline reload after each tap. Pose changes are larger. These changes
address suspected rendering causes; the exact cause of the white tile has not
been confirmed with a screenshot or device debugger. The app explains that
continuous looping is available only in its foreground preview.

Run the macOS workflow for the current revision, install its IPA with the widget
extension retained, remove old widgets, and add them again. Check that the artwork
is visible and that tapping changes poses with the phone awake. Repeat for Home
Screen, rectangular/circular Lock Screen, Reduce Motion, and Always On. Continuous
playback without updates is not supported by this implementation or claimed.

## Timer glyph test — 2026-09-27

Version 0.2.0 adds a separate **Wigy Timer Test** widget, scheduled at :00 and
:30 each hour, with a six-second paused timer whose custom font contains three
scene phases. The font is generated from the four transparent layer cutouts.
Font glyph shape and native compilation can be validated here; automatic visual
changes in an installed widget require a phone test. Apple may delay timeline
entries. The original tap widget remains for comparison.

## No visible change reported — version 0.2.1

The user reported no visible difference with 0.2.0. This does not establish
which step failed: widget selection, schedule delivery, timer update, or font
rendering. Version 0.2.1 adds an immediate AppIntent test with a visible standard
countdown and a static custom-font sample on the Home Screen. It removes the
explicit pause date and fixed intrinsic timer width, and sets white foreground
color for the dark Home Screen container. A fresh test starts two seconds after
the provider receives the request. The small Lock Screen widget can also be
tapped to start the test. The timing/font behavior still needs a phone recording.
