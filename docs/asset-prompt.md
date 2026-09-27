# Four-layer generation brief

Use `Reference/layer-sheet.png` as the reference. The checked-in prototype is a
transparent extraction of that sheet, not newly generated reconstruction. The
image-generation tool was unavailable during this task. The extraction is enough
to inspect alignment; hidden anatomy and fabric seams still need art review.

When an image-generation tool is available, use this prompt for the next pass:

> Reconstruct the reference as four independently usable transparent PNG assets
> for a SwiftUI scene. Output actual individual PNG files, never a sprite sheet,
> finished scene image, GIF, wallpaper, UI card, mockup, or widget screenshot.
>
> Use an identical 1024 × 1024 transparent canvas for every file. Keep the body
> facing forward, toward the left of the composition, and the flowing cloak to
> its right. Preserve the reference's proportions. Retain the same registration
> coordinates for every asset. Do not center or crop layers independently.
>
> 1. `character_base.png`: recognizable face, torso, arms, and legs. Complete the
>    parts hidden by hair/cloak so a small movement never reveals a missing piece.
>    Exclude hair, loose cloak, rain, and effects from this base.
> 2. `cloak.png`: only the coat and its flowing edges. Give the attachment area
>    enough overlap to cover the shoulder seam during a subtle rotation.
> 3. `hair.png`: isolated hair with a scalp attachment and flowing strands.
>    Exclude the face. Allow a small overlap at its attachment to the head.
> 4. `rain.png`: only thin rain streaks, on the same transparent canvas.
>
> Outside each subject use actual alpha zero. Do not bake in a gray/black/white
> background, checkerboard, rectangular matte, glow halo, border, text, or UI.
> Use white foreground ink with antialiased alpha. Express dark facial and
> costume details as negative space so the character remains readable when
> Apple tints the layers into a single monochrome/vibrant material.
>
> Match these anchors for drop-in compatibility with the existing prototype:
> body/hair head center near (320, 174), cloak shoulder root near (380, 280),
> feet near y=914, with transparent margins on all sides. The four files must
> stack as character base → cloak → hair → rain and form one coherent scene.
> Hair moves a few pixels; cloak rotates less than one degree around its shoulder;
> rain moves down. Keep motion seams overlapped, without duplicate hair or fabric
> remaining in the base.
>
> Do not create energy, particles, mist, flash, or sword assets in this first pass.

After replacing a layer, copy the same PNG into its matching
`Shared/LayerAssets.xcassets/<name>.imageset/` and run
`python3 scripts/validate_layers.py`. The catalog copy must match the source.
The reference sheet itself and old GIFs are never bundled in the app.

## Later passes

Once the four-layer test succeeds on a device, add separate `energy.png`,
`particles.png`, `mist.png`, `flash.png`, and `sword.png` with the same canvas and
anchors. Each requires its own opacity/position/scale behavior; none should be
baked into the character. Continuous motion in the foreground app and finite
WidgetKit update animations are separate runtime behaviors.
