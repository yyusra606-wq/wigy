# Wigy — transparent anime layers for SwiftUI

Wigy is a four-layer prototype: **character base, cloak, hair, and rain**. Both
the native app and WidgetKit extension compose those transparent PNGs in a
SwiftUI `ZStack`. The artwork has no rectangular image background or GIF player.
The first test checks transparency, registration, independent motion, and
monochrome readability before adding any more effects.

## What is included

- `Assets/Layers/`: four separate 1024 × 1024 RGBA PNGs and a registration manifest.
- `Shared/LayerAssets.xcassets/`: identical copies bundled into both targets.
- `Shared/LayerScene.swift`: one shared compositor with independent layer transforms.
- `App/`: a layer inspector, visibility switches, monochrome preview, and a
  two-second motion that can repeat inside the foreground app.
- `Widget/`: Home Screen and Lock Screen widgets with a tappable scene to request a
  short native content-update animation. Inline widgets show an icon/title.
- `project.yml` and `Config/`: reproducible Xcode app and embedded widget targets.
- `scripts/build_ipa.sh`: macOS build script that produces **`wigy.ipa`**.
  `.github/workflows/build-ipa.yml` runs it on GitHub Actions. A copy is also
  available as `build-ipa.txt` in the task Outputs.
- `docs/asset-prompt.md`: the reconstruction prompt and future effect-layer plan.

The test PNGs were **extracted from the supplied reference sheet using masks**.
They are not newly AI-generated artwork. The hair/body cutouts share the same
transform; the separate cape study is placed at the shoulder with uniform scaling.
Dark costume details become transparent negative space for monochrome rendering.
Hidden anatomy has not been generatively reconstructed, so this remains an art
pipeline test, not final production art. The image-generation tool was unavailable.

The old GIFs and frame catalog remain in `Reference/` as history. They are not in
any build target. The reference sheet is also excluded from the app.

## Scheduled timer glyph experiment

**Wigy Timer Test** is a second widget in version 0.2.0. It schedules entries
for each local hour at :00 and :30. Each entry includes a six-second countdown
that pauses at zero. A custom vector font maps countdown digits 6/5 to scene 1,
4/3 to scene 2, and 2/1 to scene 3; zero and the timer punctuation are blank.
The normal transparent scene remains faintly visible underneath. The original
**Wigy Layers** tap widget is still available.

This is an experimental timer-rendering route, not a proven WidgetKit playback
feature. iOS may delay a scheduled entry, suppress timer redraws, replace the
custom font, or alter the timer format. Test it on the phone at :00 or :30 and
record the screen for six seconds. The three poses come from the same transparent
layer cutouts; their motion is still coarse compared with the reference GIF.

Rebuild the font after changing layer cutouts with
`python3 scripts/make_timer_font.py`. It uses fonttools from
`scripts/requirements.txt`. The generated TTF is bundled only in the widget
extension.

## Widget behavior

Version 0.1.1 makes the entire scene tappable and uses four smaller, pre-cropped
transparent layers on the Lock Screen. The app preview can loop; widgets request
a two-second pose transition only when tapped. Continuous widget playback is not
supported. Lock Screen appearance and tap animations still need a device check.

## First test

1. In the app, hide each of the four layers. Check that the remaining layers stay
   registered and that there is no rectangular matte.
2. Play the two-second motion. Check the scalp and cloak attachment for gaps.
3. Toggle monochrome preview and inspect the face/torso at a small size.
4. Add **Wigy Layers** from the widget gallery. Tap the scene and check the hair, cloak, and rain transition.
5. Repeat with Reduce Motion and Always On. A still, legible composition is the
   expected fallback. The app's layer switches are inspection controls and do not
   configure the widget.

All PNGs use the same canvas and anchor positions. Never auto-trim a layer to its
visible bounds. The app uses a full two-second cycle; widgets interpolate a pose
change and request a two-second rain transition when an update occurs. Actual
motion needs a device test: iOS can suppress it. Apple also controls the surrounding
widget presentation even though the artwork itself has no background.

Supported families: iPhone small/medium/large Home Screen; iPad extra large;
Lock Screen circular/rectangular/inline. Full scenes use all four layers, while
compact accessory layouts crop the same composition around the upper body.
The inline family only has room for text and a symbol. This project uses the
families available in its Xcode 16.4 SDK, with an **iOS/iPadOS 17 minimum**.

## SideStore and a free Apple Account

The build has **no APNs, App Groups, iCloud, or paid-service entitlement**. Its
widget intent lives only in the widget extension and stores its pose in that
extension's own defaults. It needs no shared container or external server.

The IPA is unsigned. SideStore re-signs the app and widget extension using your
Apple Account. You do not need a paid Apple Developer Program membership for this
unsigned build workflow. Keep the widget extension when importing; removing it
also removes the widgets. Sideload/signing success still needs testing with your
SideStore version and device.

This free-account prototype does **not** implement the earlier server-ping/APNs
idea. Widget push capability requires the appropriate Apple provisioning; a
server cannot bypass WidgetKit's animation/update limits. Layer separation makes
independent motion possible, but does not make widgets run continuously.

With a free account, SideStore documents a seven-day refresh period, three active
apps including SideStore, and ten App IDs. The app and its extension require
separate IDs. See the [official SideStore FAQ](https://docs.sidestore.io/docs/faq)
and [Apple's membership comparison](https://developer.apple.com/support/compare-memberships/).
Do not add Apple credentials or signing certificates to this repository or workflow.

## Get `wigy.ipa` using GitHub Actions

1. The workflow is already installed at `.github/workflows/build-ipa.yml`.
   If copying this project to another repository, include that file.
2. Open **Actions → Build SideStore IPA → Run workflow**. Manual dispatch becomes
   available once the workflow is on the default branch. Pushes to `main` and the
   assigned task branch also start it.
3. Wait for the macOS job to succeed. It checks the PNGs, generates the Xcode
   project, compiles an unsigned **device** app, and embeds `WigyWidgets.appex`.
4. Download the **wigy-ipa** artifact. Unzip the artifact wrapper to obtain
   **`wigy.ipa`**; the wrapper ZIP is not the IPA.
5. Import `wigy.ipa` into SideStore and keep its extension. Open Wigy once, then
   add its widgets from the system gallery. Refresh it through SideStore before
   the free provisioning period expires.

The workflow selects Xcode 16.4 on `macos-15`, installs XcodeGen 2.44.1 with a
verified SHA-256, and uses no signing secrets. `scripts/validate_ipa.py` rejects
source ZIPs, simulator builds, missing compiled assets, and missing widget bundles.
The artifact is only produced after a successful Xcode build. Source files and a
workflow alone are not an IPA.

### Build on your Mac instead

Install Xcode 16.4 or newer and XcodeGen 2.44.1, then run:

```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r scripts/requirements.txt
python3 scripts/validate_layers.py
bash scripts/build_ipa.sh
```

The result is `build/wigy.ipa`. For interactive Xcode development, run
`xcodegen generate --spec project.yml` and open `Wigy.xcodeproj`. Select the Wigy
scheme. SideStore handles signing the packaged app separately.

### Reproduce the current extraction

```bash
python3 scripts/extract_layers.py
python3 scripts/make_icon.py
python3 scripts/make_accessory_layers.py
python3 scripts/validate_layers.py
python3 scripts/preview_layers.py --output build/previews
```

These masks are specific to the supplied sheet and deliberately record how the
prototype was made. For newly reconstructed art, follow `docs/asset-prompt.md`
instead of overwriting it with the extraction script.

## Verification status

See `docs/verification.md` for the checks performed and the remaining macOS/device
checks. The Linux sandbox cannot compile SwiftUI or manufacture a valid iOS binary.
A successful remote build is still required before an actual `wigy.ipa` can be shared.

Apple references: [Widget animations](https://developer.apple.com/documentation/widgetkit/animating-data-updates-in-widgets-and-live-activities),
[interactive widgets](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities),
[WidgetKit pushes](https://developer.apple.com/documentation/widgetkit/updating-widgets-with-widgetkit-push-notifications).
