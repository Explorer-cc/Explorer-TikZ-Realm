# TikZ Illustration Reconstruction: Execution Steps, File Index, and Ten Rounds of Changes

Chinese counterpart: [note-cn.md](note-cn.md). Both documents follow the same section structure.

## 1. Scope and final result

The input was [example-image.png](example-image.png), measuring **243 × 185 pixels**. The task was to reconstruct the boy, kite, and tree with TikZ; remove the blue “?”, “4 m”, and “13 m” labels and the diagonal, horizontal, and vertical dimension guides; perform ten rendering/comparison rounds; and retain intermediate files in `tmp/`.

The actual kite string, blue shoes, and dark-blue kite knot belong to the illustration rather than the dimension annotations, so they were retained. The original crops the tree crown at the top edge; the reconstruction preserves that composition rather than inventing a complete treetop.

The final source is [mwe.tex](mwe.tex), and the final vector output is [mwe.pdf](mwe.pdf). The illustration uses TikZ filled paths, cubic Bézier curves, and strokes. The reference bitmap was not embedded in the PDF, and the image was not recreated as a grid of colored pixel tiles. Ten distinct source snapshots were saved, each actually compiled and rendered. Round 1 is the initial baseline; rounds 2–10 modify the preceding version.

The result is a close vector approximation, not a pixel-identical copy. Raster blur, compression artifacts, and local edge texture were not reproduced. Areas covered by the blue annotations also lack an unobstructed reference against which to compare the reconstruction.

## 2. Concrete steps in execution order

### 2.1 Inspecting the input and available tools

1. Inspected the working directory and confirmed the presence of `example-image.png` and an initially empty `mwe.tex`.
2. Opened the reference and distinguished the three blue labels and three dimension guides from the actual kite string that needed to remain.
3. Consulted the Chinese-writing and PDF-rendering workflow instructions.
4. Ran `where.exe pdflatex xelatex lualatex pdftoppm python` to locate executables. TeX Live, Poppler, and Python were already installed. Actual compilation used `pdflatex`; rasterization used `pdftoppm`. No dependencies were installed.
5. Checked that Pillow, NumPy, OpenCV, SciPy, and PyMuPDF (`fitz`) were available in Python.
6. Loaded the reference with Pillow, converted it to RGB, confirmed its dimensions, and created `tmp/`. Environment and dependency checks produced session output, not separate saved terminal logs.

### 2.2 Enlarging, cropping, and sampling the reference

7. Enlarged the reference to **972 × 740** and saved `tmp/reference-4x.png`. This is an enlarged reference image, not a TikZ rendering.
8. Cropped the boy, kite, and tree separately and enlarged each crop sixfold:

| Object | Reference crop `(left, top, right, bottom)` | Enlarged dimensions | File |
|---|---|---|---|
| Boy | `(23,88,62,175)` | 234 × 522 | `tmp/boy-detail.png` |
| Kite | `(137,6,163,32)` | 156 × 156 | `tmp/kite-detail.png` |
| Tree | `(104,0,202,175)` | 588 × 1050 | `tmp/tree-detail.png` |

Crop coordinates use Pillow conventions: right and bottom boundaries are exclusive.

9. Inspected the enlarged images for hair, face, clothes, hands, feet, kite panels, irregular crown lobes, the orange trunk band, and bark strokes.
10. Read RGB values from selected reference pixels to establish initial colors. Further skin, kite, and outline samples were taken later. These values were printed in the session; no standalone color-sampling data file was saved.

### 2.3 Building the initial pure-TikZ reconstruction

11. Used the `standalone` document class with TikZ and `border=0pt`.
12. Set `x=1bp,y=-1bp`: the origin is at the upper left, x increases rightward, and y increases downward. One reference-pixel coordinate maps to one drawing unit. Here bp is a PDF typesetting unit, not a claim about the reference image’s physical printing DPI.
13. Fixed the bounding box and clipping region to `(0,0)`–`(243,185)` to preserve composition and whitespace.
14. Defined colors for foliage, bark, the orange band, skin, hair, clothes, shorts, shoes, and kite parts, plus adjustable line-width and position parameters.
15. Drew the trunk, orange band, bark marks, crown, and internal crown curves in their required stacking order.
16. Drew the actual string from the boy’s hand to the kite knot. Did not create dimension-guide paths or label nodes.
17. Drew four alternating kite panels, the outer frame, crossing spars, and the dark-blue knot.
18. Drew the boy back-to-front: arms, legs, face and neck, shirt, shorts, shoes, hair, and the short eye stroke.
19. Compiled the initial source into `tmp/mwe.pdf`, `tmp/mwe.log`, and `tmp/mwe.aux`, then rasterized it as `tmp/initial.png`. The generically named PDF, log, and auxiliary file were later overwritten by the final compilation. `initial.png` preserves the initial appearance, while `tmp/iteration-01/` holds the complete independent baseline snapshot.
20. Inspected the initial rendering and found that skin and shirt outlines were not actually appearing. Round 2 corrected this by explicitly adding `draw=ink`.

### 2.4 Establishing comparison and archiving

21. Created `tmp/compare.py` with functions for reference loading, blue-annotation masking, regional scoring, compilation, rasterization, and three-panel comparisons.
22. Identified blue annotations using color thresholds and dilated the exclusion mask so antialiased edges around removed guides would not be counted as reconstruction errors. Rectangles containing the shoes and kite knot were first removed from the blue candidates.
23. Saved `tmp/comparison-valid-mask.png`. It shows which locations across the entire image are not excluded by the blue-mask rule; it is not the union of the four scoring regions.
24. Each `run_round(number, note)` call copied the current root `mwe.tex` into that round’s directory, compiled it, captured compiler output, rendered a PNG, calculated metrics, created a comparison image, and updated the combined history.
25. Loaded the comparison helper as a Python module. Python automatically created `tmp/__pycache__/compare.cpython-312.pyc`, a bytecode cache rather than a design deliverable.
26. The ten formal rounds are `tmp/iteration-01/` through `tmp/iteration-10/`. The earlier `initial.png` is a baseline preview, not an eleventh round.

### 2.5 Measurements and detailed checks between rounds

27. In the round-2 rendering, selected pixels close to each fill color, applied 3 × 3 erosion to reduce edge mixing, excluded the blue mask, and sampled median RGB values at corresponding reference locations. Round 3 updated seven colors from these measurements.
28. Used OpenCV affine translations and SciPy Nelder–Mead optimization to estimate subpixel offsets for the boy and tree. The boy estimate was approximately `(0.195,-0.157)`; round 4 applied `(0.20,-0.16)`. The tree estimate was very small and was not applied: `TreeX` and `TreeY` stayed at 0.
29. Searched reference columns x=62–107 for gray-brown string pixels, sampled their positions, and fitted a quadratic polynomial. Also tried least-squares fitting of Bézier control points. These experiments only produced session output; no independent result file was saved.
30. The candidate Bézier control points from that fit were not written into the final source. The existing intermediate controls `(72.9,79.1)` and `(115.0,53.9)` were retained; later changes affected only the hand-side endpoint and stroke width. The fitting experiment must not be described as an applied curve reconstruction.
31. After round 5, enlarged and placed reference/render crops side by side in `tmp/boy-round5.png` and `tmp/kite-round5.png`. The reference is on the left and the rendering on the right. These were used to inspect contours, panels, and stroke weight.
32. Continued sampling reference pixels around the hands, face, legs, shorts edges, hair, and internal crown strokes to guide color and outline changes in rounds 6–8.
33. After round 7, estimated a kite translation of about `(0.111,0.114)`; round 8 applied `(0.11,0.11)`.
34. After round 8, generated `tmp/boy-round8.png` and `tmp/kite-round8.png` to compare hair edges, the shoe toe, the eye stroke, and the knot before implementing round 9.
35. Used actual rendered output and numerical results to guide subsequent edits, ending with final tree-outline and string-width adjustments in round 10.

### 2.6 Final compilation, aggregation, and verification

36. After round 10, compiled the final root `mwe.tex` directly instead of merely copying an earlier round’s PDF. This compilation returned exit code 0.
37. The final compilation updated `tmp/mwe.pdf`, `tmp/mwe.log`, and `tmp/mwe.aux`. Copied the PDF to root-level `mwe.pdf` for delivery.
38. Rendered the final PDF as `tmp/final.png` and generated `tmp/final-comparison.png`.
39. Exported the ten in-memory records to `tmp/iterations.csv`. `tmp/iterations.json` had already been updated throughout the rounds.
40. Reduced the ten renderings to reference-image dimensions and assembled a 5-column × 2-row contact sheet, `tmp/all-iterations.png`, labeled with round numbers and weighted errors.
41. Inspected the final PDF with PyMuPDF: **1 page**, approximately **242.997 × 184.998 PDF points**, and **0 embedded raster images**. The tiny discrepancy from 243 × 185 results from unit conversion and output precision.
42. Verified byte-for-byte equality between root `mwe.tex` and the round-10 source; confirmed that all ten rounds contained source, PDF, PNG, comparison, and metrics files; and confirmed that all ten source snapshots were distinct.
43. Recomputed the final score and visually inspected the final rendering, ten-round overview, and final comparison to check removal of the blue dimension text and guides.
44. Retained all intermediate files as requested, including round snapshots, crops, logs, and the Python cache.

## 3. Pixel-comparison method and limitations

### 3.1 Resolution and exclusion rules

Each PDF was rendered at **972 × 740**, then downsampled with Lanczos to **243 × 185** for scoring. The comparison operates on RGB channels, not PDF path coordinates.

A pixel is a blue candidate when all three conditions hold: `B > R + 16`, `B > G + 19`, and `G < 150`. Candidates were cleared within the shoe rectangle `x∈[24,51), y∈[158,175)` and knot rectangle `x∈[137,148), y∈[23,34)` before dilation with a 5 × 5 all-ones kernel.

This is an approximate automatic mask, not manual pixel-level segmentation. Dilation also excludes some illustration pixels next to the annotations; retained areas are not exact object segmentations either. The quality of reconstructed content in masked areas requires visual judgment and cannot be established by this score.

### 3.2 Regions and formula

| Region | Reference bounds `(x0,y0,x1,y1)` | Additional conditions | Weight |
|---|---|---|---:|
| boy | `(22,89,62,175)` | Exclude the blue mask | 0.35 |
| tree | `(105,0,202,175)` | Exclude the blue mask | 0.40 |
| kite | `(137,7,163,33)` | Exclude the blue mask | 0.20 |
| string | `(53,30,143,105)` | Minimum reference channel < 235 and x < 108; exclude the blue mask | 0.05 |

Right and bottom boundaries are exclusive. Per-pixel error is the mean absolute difference across the three channels. Regional MAE averages this error over valid pixels. The total is:

`weighted_mae = 0.35 × boy + 0.40 × tree + 0.20 × kite + 0.05 × string`

Lower is better; channel values range from 0 to 255. This is a custom region-weighted MAE, not a similarity percentage, whole-image MAE, SSIM, or PSNR. Regions overlap: the tree region includes the kite, and the string region may include hand pixels. Changing one object can therefore affect multiple scores. The string metric concentrates on darker pixels already present in the reference and inadequately penalizes erroneous extra strokes elsewhere, making visual inspection necessary.

### 3.3 Reading the comparison images

Each `comparison.png` measures **2187 × 590**. The left panel preserves the annotated original, the middle panel shows the TikZ rendering, and the right panel shows absolute error. Stronger red indicates greater differences; gray indicates excluded pixels. Error intensity is multiplied by four and clipped at 255. Background outside the union of scoring regions is light gray.

The reference panel is not an inpainted, annotation-free ground truth. Retaining the original avoids treating invented replacement pixels as reference evidence.

## 4. Mapping every file in tmp

At the time of this inventory, `tmp/` contained **100 files**: the 20 entries below plus eight files in each of ten round directories. Each round in Section 6 includes individual links to its eight files, covering all 100 files.

### 4.1 Files outside the round directories: 20 entries

| File | Creation stage and purpose |
|---|---|
| [tmp/reference-4x.png](tmp/reference-4x.png) | Fourfold enlargement of the original for composition inspection. |
| [tmp/boy-detail.png](tmp/boy-detail.png) | Initial boy crop, enlarged sixfold. |
| [tmp/kite-detail.png](tmp/kite-detail.png) | Initial kite crop, enlarged sixfold. |
| [tmp/tree-detail.png](tmp/tree-detail.png) | Initial tree crop, enlarged sixfold. |
| [tmp/initial.png](tmp/initial.png) | Initial TikZ preview generated before formal round archiving. |
| [tmp/compare.py](tmp/compare.py) | Compilation, scoring, archiving, and comparison functions; not an automatic optimizer. |
| [tmp/comparison-valid-mask.png](tmp/comparison-valid-mask.png) | 243 × 185 mask: white is not excluded, black is excluded. |
| [tmp/__pycache__/compare.cpython-312.pyc](tmp/__pycache__/compare.cpython-312.pyc) | Python 3.12 bytecode cache automatically generated on module import. |
| [tmp/boy-round5.png](tmp/boy-round5.png) | Round-5 boy side-by-side crop, 624 × 688. |
| [tmp/kite-round5.png](tmp/kite-round5.png) | Round-5 kite side-by-side crop, 416 × 216. |
| [tmp/boy-round8.png](tmp/boy-round8.png) | Round-8 boy side-by-side crop, 624 × 688. |
| [tmp/kite-round8.png](tmp/kite-round8.png) | Round-8 kite side-by-side crop, 416 × 216. |
| [tmp/iterations.json](tmp/iterations.json) | Changes, four regional MAEs, and weighted MAE for all rounds; updated after each round. |
| [tmp/iterations.csv](tmp/iterations.csv) | Final export of the same records for spreadsheet use, encoded as UTF-8 with BOM. |
| [tmp/mwe.aux](tmp/mwe.aux) | Auxiliary file from final root-source compilation; overwrote its initial counterpart. |
| [tmp/mwe.log](tmp/mwe.log) | Final root-source compilation log; overwrote its initial counterpart. |
| [tmp/mwe.pdf](tmp/mwe.pdf) | Final root-source compilation output, copied to the root delivery PDF. |
| [tmp/final.png](tmp/final.png) | Final PDF preview at 972 × 740. |
| [tmp/final-comparison.png](tmp/final-comparison.png) | Final reference/render/error comparison. |
| [tmp/all-iterations.png](tmp/all-iterations.png) | Ten thumbnails with weighted scores, 1215 × 430. |

### 4.2 The eight files in every round

| Filename | Meaning |
|---|---|
| `mwe.tex` | Complete source snapshot at that round, unaffected by later edits to the root source. |
| `mwe.pdf` | Single-page vector output actually compiled from that snapshot. |
| `mwe.png` | Rasterization of that round’s PDF at 972 × 740. |
| `comparison.png` | Original reference, round rendering, and masked error visualization. |
| `metrics.json` | Round number, English change note, boy/tree/kite/string scores, and weighted_mae. |
| `mwe.log` | Detailed log written by the TeX engine. |
| `mwe-console.txt` | Concatenated compiler stdout and stderr saved by Python; not the complete interactive session or a separate Poppler log. |
| `mwe.aux` | Auxiliary state automatically generated by LaTeX. |

## 5. Reproduction entry points and verification boundaries

Run these commands from the project root to recompile the final source. The project already contains `tmp/`.

```sh
pdflatex -interaction=nonstopmode -halt-on-error -output-directory=tmp mwe.tex
pdftoppm -scale-to-x 972 -scale-to-y 740 -singlefile -png tmp/mwe.pdf tmp/final
```

These commands update the final PDF and preview in `tmp/`. They do not automatically update root-level `mwe.pdf` or regenerate the ten-round overview.

`compare.py` provides `score(image)`, `compile_tex(source,outdir,stem='mwe')`, `comparison(image,destination)`, and `run_round(number,note)`. Simply running it does not execute ten rounds. Source edits, color sampling, translation estimation, and final overview generation were performed interactively and are not all encapsulated in that helper.

Importing the script rewrites `comparison-valid-mask.png`. Its `history` starts empty; `run_round` rewrites the combined JSON and writes into the selected numbered directory. Do not call it merely to inspect history, since doing so may overwrite archived results. Read the existing snapshots, JSON, CSV, and images instead.

Checks actually performed were independent final compilation, PDF page count and dimensions, embedded-image count, final-source/snapshot equality, distinctness of all ten snapshots, round artifact completeness, and visual inspection. No check established equality of every pixel, and no pixel-identical result is claimed.

## 6. Detailed changes in all ten rounds

Parameter changes below were checked against adjacent archived `mwe.tex` snapshots; scores come from each round’s `metrics.json`. The eight links under every round correspond to Section 4.2.

### Round 1: Establishing the baseline

- Manually constructed the Bézier contours, fills, stacking order, and initial palette. Blue dimension annotations were omitted from the outset.
- Initial widths: tree 0.90 bp, boy 0.95 bp, kite 0.80 bp, string 0.64 bp. Tree and boy translation parameters were all 0.
- Compiled and archived the first complete baseline. Skin and shirt outlines were not yet appearing correctly.
- Weighted MAE: **12.407693**.
- Files: [source](tmp/iteration-01/mwe.tex) · [PDF](tmp/iteration-01/mwe.pdf) · [render](tmp/iteration-01/mwe.png) · [comparison](tmp/iteration-01/comparison.png) · [metrics](tmp/iteration-01/metrics.json) · [TeX log](tmp/iteration-01/mwe.log) · [console](tmp/iteration-01/mwe-console.txt) · [auxiliary](tmp/iteration-01/mwe.aux).

### Round 2: Restoring missing boy outlines

- Explicitly added `draw=ink` to six `\path` commands: the two arms, two legs, face/neck, and shirt.
- Did not change the coordinates of these paths. This fixed stroke activation rather than redrawing the shapes.
- Weighted MAE: **9.862437**.
- Files: [source](tmp/iteration-02/mwe.tex) · [PDF](tmp/iteration-02/mwe.pdf) · [render](tmp/iteration-02/mwe.png) · [comparison](tmp/iteration-02/comparison.png) · [metrics](tmp/iteration-02/metrics.json) · [TeX log](tmp/iteration-02/mwe.log) · [console](tmp/iteration-02/mwe-console.txt) · [auxiliary](tmp/iteration-02/mwe.aux).

### Round 3: Calibrating colors from interior-pixel medians

| Color | Previous RGB | Updated RGB |
|---|---|---|
| leaf | 171,205,82 | 169,208,79 |
| bark | 233,198,160 | 232,195,159 |
| band | 240,170,107 | 240,169,107 |
| hair | 71,70,68 | 71,71,71 |
| shirt | 251,248,188 | 252,247,191 |
| shorts | 244,67,36 | 250,73,37 |
| shoe | 40,107,139 | 42,105,142 |

- No geometry coordinates changed in this round.
- Weighted MAE: **9.592780**.
- Files: [source](tmp/iteration-03/mwe.tex) · [PDF](tmp/iteration-03/mwe.pdf) · [render](tmp/iteration-03/mwe.png) · [comparison](tmp/iteration-03/comparison.png) · [metrics](tmp/iteration-03/metrics.json) · [TeX log](tmp/iteration-03/mwe.log) · [console](tmp/iteration-03/mwe-console.txt) · [auxiliary](tmp/iteration-03/mwe.aux).

### Round 4: Aligning the whole boy

- Changed `BoyX: 0 → 0.20` and `BoyY: 0 → -0.16`: rightward by 0.20 and upward by 0.16 reference-coordinate units.
- Translated the entire boy scope instead of editing each body part. The independent string endpoint had not yet been moved to match.
- Weighted MAE: **9.446124**.
- Files: [source](tmp/iteration-04/mwe.tex) · [PDF](tmp/iteration-04/mwe.pdf) · [render](tmp/iteration-04/mwe.png) · [comparison](tmp/iteration-04/comparison.png) · [metrics](tmp/iteration-04/metrics.json) · [TeX log](tmp/iteration-04/mwe.log) · [console](tmp/iteration-04/mwe-console.txt) · [auxiliary](tmp/iteration-04/mwe.aux).

### Round 5: Strengthening boy and kite outlines

- Changed `BoyWidth: 0.95 → 1.20 bp`.
- Changed `KiteWidth: 0.80 → 1.15 bp`.
- No shape coordinates changed. Generated the round-5 boy and kite detail comparisons afterward.
- Weighted MAE: **8.982546**.
- Files: [source](tmp/iteration-05/mwe.tex) · [PDF](tmp/iteration-05/mwe.pdf) · [render](tmp/iteration-05/mwe.png) · [comparison](tmp/iteration-05/comparison.png) · [metrics](tmp/iteration-05/metrics.json) · [TeX log](tmp/iteration-05/mwe.log) · [console](tmp/iteration-05/mwe-console.txt) · [auxiliary](tmp/iteration-05/mwe.aux).

### Round 6: Adjusting skin, kite colors, and tree strokes

- Changed `skin: (242,195,141) → (239,186,130)`.
- Changed `pink: (211,128,184) → (221,122,177)`.
- Changed `cyan: (140,208,218) → (136,209,223)`.
- Changed `TreeWidth: 0.90 → 1.10 bp`.
- Changed the upper internal crown stroke from `0.75 → 0.95 bp` and the lower internal crown stroke from `0.80 → 1.00 bp`.
- Weighted MAE: **8.595287**.
- Files: [source](tmp/iteration-06/mwe.tex) · [PDF](tmp/iteration-06/mwe.pdf) · [render](tmp/iteration-06/mwe.png) · [comparison](tmp/iteration-06/comparison.png) · [metrics](tmp/iteration-06/metrics.json) · [TeX log](tmp/iteration-06/mwe.log) · [console](tmp/iteration-06/mwe-console.txt) · [auxiliary](tmp/iteration-06/mwe.aux).

### Round 7: Refining the actual kite string

- Changed `StringWidth: 0.64 → 0.95 bp`.
- Moved the hand-side endpoint from `(55.6,102.6)` to `(55.8,102.44)`, matching the boy’s overall translation.
- Retained the intermediate control points and the curve near the kite. Did not apply the earlier least-squares candidate control points.
- Weighted MAE: **8.043661**. The string-region error dropped from approximately 24.731 in the preceding round to 14.258.
- Files: [source](tmp/iteration-07/mwe.tex) · [PDF](tmp/iteration-07/mwe.pdf) · [render](tmp/iteration-07/mwe.png) · [comparison](tmp/iteration-07/comparison.png) · [metrics](tmp/iteration-07/metrics.json) · [TeX log](tmp/iteration-07/mwe.log) · [console](tmp/iteration-07/mwe-console.txt) · [auxiliary](tmp/iteration-07/mwe.aux).

### Round 8: Subpixel kite alignment and stronger boy edges

- Added `shift={(0.11,0.11)}` to the whole kite scope, moving the kite and knot rightward and downward by 0.11 each. The independent string path is outside that scope.
- Changed `shortedge: (156,80,44) → (139,59,35)` to darken the shorts outline.
- Changed the separate hair outline from `0.75 → 1.05 bp`.
- Generated the round-8 boy and kite detail comparisons.
- Weighted MAE: **7.960093**.
- Files: [source](tmp/iteration-08/mwe.tex) · [PDF](tmp/iteration-08/mwe.pdf) · [render](tmp/iteration-08/mwe.png) · [comparison](tmp/iteration-08/comparison.png) · [metrics](tmp/iteration-08/metrics.json) · [TeX log](tmp/iteration-08/mwe.log) · [console](tmp/iteration-08/mwe-console.txt) · [auxiliary](tmp/iteration-08/mwe.aux).

### Round 9: Shoe toe, eye, and knot details

- Changed `knot: (47,91,138) → (47,54,126)` toward a darker blue-violet.
- Narrowed the right shoe toe: changed the upper Bézier controls from `(47.1,167.7)` and `(49.8,168.2)` to `(46.6,167.7)` and `(49.0,168.2)`, the toe endpoint from `(49.7,170.2)` to `(48.9,170.2)`, and the first return-curve control from `(49.3,172.8)` to `(48.5,172.8)`.
- Increased the eye stroke from `0.65 → 0.95 bp`; moved its endpoints from `(47.2,103.7)–(47.5,105.4)` to `(47.0,103.6)–(47.3,105.3)`.
- Weighted MAE: **7.898198**.
- Files: [source](tmp/iteration-09/mwe.tex) · [PDF](tmp/iteration-09/mwe.pdf) · [render](tmp/iteration-09/mwe.png) · [comparison](tmp/iteration-09/comparison.png) · [metrics](tmp/iteration-09/metrics.json) · [TeX log](tmp/iteration-09/mwe.log) · [console](tmp/iteration-09/mwe-console.txt) · [auxiliary](tmp/iteration-09/mwe.aux).

### Round 10: Final stroke adjustment and source comments

- Changed `TreeWidth: 1.10 → 1.20 bp`.
- Changed `StringWidth: 0.95 → 1.15 bp`.
- Added four source-comment lines documenting the ten-round archive location, removed annotations, retained illustration elements, and the limitation that raster blur and compression were not reproduced.
- Weighted MAE: **7.797865**, approximately **37.153%** lower than round 1. This is a reduction in error, not a claim such as “97% similarity.”
- Boy-region MAE rose slightly from 9.621779 in round 9 to 9.632924, while improvements in the tree and string regions helped reduce the weighted total. Not every region improved monotonically in every round.
- Files: [source](tmp/iteration-10/mwe.tex) · [PDF](tmp/iteration-10/mwe.pdf) · [render](tmp/iteration-10/mwe.png) · [comparison](tmp/iteration-10/comparison.png) · [metrics](tmp/iteration-10/metrics.json) · [TeX log](tmp/iteration-10/mwe.log) · [console](tmp/iteration-10/mwe-console.txt) · [auxiliary](tmp/iteration-10/mwe.aux).
