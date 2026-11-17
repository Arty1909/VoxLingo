# VoxLingo brand assets

The supplied raster logo and wordmark were cleaned using the built-in ImageGen tool (not the API/CLI). The original attachments were not overwritten.

- `app_icon.png`: approved cleaned square symbol, opaque light background.
- `wordmark.png`: cleaned horizontal VoxLingo logo for the Flutter header.
- `browser_icon_round.png`: enlarged globe on a pale circular disk, with actual transparent alpha outside the disk. Used only for browser favicon and regular Web manifest icons.
- `../../tool/update_icons.ps1`: repeatable resizing and PNG/ICO packaging for Android, iOS, macOS, Windows, Linux and Web. Run from PowerShell; requires System.Drawing (Windows). No API calls.

The header uses a darken blend against the existing page background to avoid a white rectangle. It retains a screen-reader label. App icons use a white background for legibility; iOS resources are RGB without alpha. Adaptive Android and maskable Web icons include additional safe-zone padding. Linux's existing application ID remains unchanged; packaging should install the generated `share/applications` and `share/icons` resources and make `voxlingo` available on PATH.

Browser icons now have a separate circular master. Run `../../tool/update_icons.ps1 -WebOnly` to resize it without changing any native platform icon. Alpha is preserved in 32-bit PNGs; no background removal or redrawing is performed by the script. `favicon-round-v2.png` has a new URL to avoid the old favicon cache. Native icons, the header wordmark, and maskable safe-zone icons remain unchanged by this browser-only update.

## ImageGen prompt set

### Circular browser icon (built-in ImageGen, not CLI)

Use case: precise-object-edit. Edit target: approved VoxLingo globe logo. Preserve globe meridians and parallels, five rounded vertical sound bars, exactly two wrapping circular arrows, violet lower-left through blue to cyan upper-right colors. Remove the white square and place the enlarged globe on one pale #FAFBFF circular disk. Disk occupies 98 percent of canvas width; globe approximately 92 percent with only a narrow protective rim. Thicken fine strokes slightly for favicon legibility, preserving separate bars and arrowheads. Outside the disk must be genuinely transparent alpha, not a white rectangle or rendered checkerboard. Inside gaps remain pale white. Crisp flat logo, no shadows, texture, lettering, extra symbols or clipping. Original master remains unchanged; output saved as browser_icon_round.png.

### Symbol cleanup

Use case: precise-object-edit. Edit target: the attached VoxLingo symbol. Clean up this exact logo for a professional app icon. Preserve its identity: globe with curved meridians and parallels, five rounded vertical voice waveform bars, two circular translation arrows, violet lower-left through royal blue to cyan upper-right gradient. Repair all jagged edges, cyan speckle debris, ragged cutouts, warped curves and accidental bulges. Smooth consistent line thickness, geometrically balanced globe, symmetric waveform. Keep the recognizable composition and arrow directions, but remove the accidental extra pointed spur at the bottom-left of the circular arc (only two intentional arrowheads). Crisp flat vector-like finish, no texture, no shadows, no glow, no lettering. Actual transparent alpha background, including every negative-space hole: NOT black, NOT checkerboard baked in. Centered square 1024x1024 image with about 10 percent clear margin around the logo. Output one cleaned symbol only.

The first output had a rendered checkerboard instead of alpha and was not shipped. The following correction produced the approved opaque master:

Use case: precise-object-edit. Edit target is the attached cleaned VoxLingo globe waveform and circular arrows symbol. Preserve the symbol exactly, all geometry, scale, placement and violet-blue-cyan gradients. Change ONLY the background: replace ALL checkerboard cells with a perfectly uniform solid pure white #FFFFFF background, including every hole and gap inside the globe and between the waveform bars. No checkerboard, no grey texture, no shadow, no border, no typography. White must be uniformly #FFFFFF corner to corner. Square production app icon.

### Wordmark cleanup

Use case: precise-object-edit. Image 1 is the edit target: VoxLingo horizontal logo. Image 2 is the cleaned symbol reference that must replace the noisy symbol in image 1. Produce a polished wide horizontal production logo, 3:1 aspect ratio, pure solid white #FFFFFF background. Keep original identity, bold rounded geometric sans-serif wordmark with exact case-sensitive text 'VoxLingo' (V o x L i n g o), Vox in deep indigo-violet and Lingo in royal-blue to cyan. Clean all speckles, jagged outlines, holes and accidental protrusions in the lettering; smooth contours and consistent letter spacing, retain the distinctive bold typography. Use the exact globe-waveform-circle-arrows design from image 2 at left, with same proportions, colors and two arrowheads. Symbol and wordmark vertically balanced, no extra decorative elements, no slogan, no duplicate symbols. Logo fits inside canvas with 4 percent horizontal margin, no clipping. Absolutely uniform white background including all holes; NO checkerboard or shadows. High-resolution crisp flat vector-like logo art.

Final targeted correction:

Use case: precise-object-edit. Make ONE targeted correction to this horizontal VoxLingo logo. The globe symbol at the LEFT has an unwanted THIRD triangular spur pointing downward-left from its lower-left circumference, at approximately 7 o'clock, BELOW the real arrowhead at 9 o'clock. REMOVE ONLY this extra triangular spur at 7 o'clock and smoothly round that section into the lower circular arc. Keep the intended left upward-pointing arrowhead at 9 o'clock and the upper-right arrowhead at 2 o'clock unchanged. Final logo must have EXACTLY TWO arrowheads, not three. Keep ALL lettering 'VoxLingo', gradients, white background, layout, size and other lines unchanged. Do not add anything. White fill where the unwanted triangle was.
