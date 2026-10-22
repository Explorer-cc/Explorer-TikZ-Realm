#set page(width: auto, height: auto, margin: 12pt)
#set text(font: "Libertinus Sans", lang: "en", size: 10pt)

// ---------- geometry ----------
#let lh = 14pt // height of one codon line; everything vertical derives from it
#let gap = 6pt // gutter between cells
#let pad = 4pt // inner padding of main cells
#let idx = 18pt // width/height of the teal index cells
#let panel-w = 80pt // width of a main cell
#let codon-w = 32pt // width of the codon column inside a main cell

#let teal = teal.lighten(25%)
#let yellow = yellow.lighten(45%)
#let stop-color = red.darken(30%)
#let met-color = blue.darken(25%)

// ---------- data ----------
#let bases = ("U", "C", "A", "G")

// (lines, name, color). Groups in a cell sum to 4 lines, top to bottom.
#let groups = (
  UU: ((2, "Phe"), (2, "Leu")),
  UC: ((4, "Ser"),),
  UA: ((2, "Tyr"), (1, "STOP", stop-color), (1, "STOP", stop-color)),
  UG: ((2, "Cys"), (1, "STOP", stop-color), (1, "Trp")),
  CU: ((4, "Leu"),),
  CC: ((4, "Pro"),),
  CA: ((2, "His"), (2, "Gln")),
  CG: ((4, "Arg"),),
  AU: ((3, "Ile"), (1, "Met", met-color)),
  AC: ((4, "Thr"),),
  AA: ((2, "Asn"), (2, "Lys")),
  AG: ((2, "Ser"), (2, "Arg")),
  GU: ((4, "Val"),),
  GC: ((4, "Ala"),),
  GA: ((2, "Asp"), (2, "Glu")),
  GG: ((4, "Gly"),),
)

// ---------- building blocks ----------
// n lines tall, content vertically centered
#let line-box(n, body, ..args) = box(height: n * lh, width: 100%, align(horizon, body))

#let codon-lines(prefix) = stack(
  dir: ttb,
  ..bases.map(b => line-box(1, align(center, prefix + b))),
)

// Right curly brace drawn as a path. It is shorter than its n lines by 2*brace-inset,
// so adjacent braces keep a visible gap and never touch.
#let brace-inset = 2.5pt
#let brace-w = 6pt
#let brace(n) = {
  let h = n * lh - 2 * brace-inset
  let w = brace-w
  box(height: n * lh, width: w, align(horizon, curve(
    stroke: 0.7pt + black,
    curve.move((0pt, 0pt)),
    curve.cubic((w / 2, 0pt), (w / 2, h * 0.1), (w / 2, h * 0.25)),
    curve.line((w / 2, h * 0.4)),
    curve.cubic((w / 2, h * 0.45), (w * 0.75, h * 0.5), (w, h * 0.5)),
    curve.cubic((w * 0.75, h * 0.5), (w / 2, h * 0.55), (w / 2, h * 0.6)),
    curve.line((w / 2, h * 0.75)),
    curve.cubic((w / 2, h * 0.9), (w / 2, h), (0pt, h)),
  )))
}

#let group(spec) = {
  let (n, name, ..rest) = spec
  let color = if rest.len() > 0 { rest.first() } else { black }
  grid(
    columns: (8pt, 1fr),
    rows: n * lh,
    column-gutter: 3pt,
    if n >= 2 { brace(n) } else { none },
    align(horizon + left, text(fill: color, weight: "bold", size: 9pt, name)),
  )
}

#let main-cell(first, second) = grid.cell(
  fill: yellow,
  inset: (x: pad, y: pad),
  grid(
    columns: (codon-w, 1fr),
    column-gutter: 2pt,
    codon-lines(first + second),
    stack(dir: ttb, ..groups.at(first + second).map(group)),
  ),
)

#let index-cell(body, ..args) = grid.cell(
  fill: teal,
  inset: 0pt,
  align: center + horizon,
  ..args,
  text(weight: "bold", body),
)

#let axis-label(body, ..args) = grid.cell(
  stroke: none,
  inset: 0pt,
  align: center + horizon,
  ..args,
  text(weight: "bold", size: 12pt, body),
)

// ---------- codon chart ----------
#let blank = grid.cell(stroke: none, [])

#let chart = {
  let main-h = 4 * lh + 2 * pad
  grid(
    columns: (14pt, idx, ..(panel-w,) * 4, idx, 14pt),
    rows: (14pt, idx, ..(main-h,) * 4),
    column-gutter: gap,
    row-gutter: gap,
    stroke: 0.7pt + black,

    // row 0: "Second letter" (corners are borderless blanks)
    blank, blank,
    axis-label(colspan: 4)[Second letter],
    blank, blank,

    // row 1: second-base header
    blank, blank,
    ..bases.map(b => index-cell(b)),
    blank, blank,

    // rows 2-5: first base | 4 main cells | third base.
    // Rowspan label cells occupy the outer columns of rows 3-5, so only row 2 emits them.
    ..for (i, first) in bases.enumerate() {
      (
        ..if i == 0 { (axis-label(rowspan: 4, rotate(-90deg, reflow: true)[First letter]),) } else { () },
        index-cell(first),
        ..bases.map(second => main-cell(first, second)),
        index-cell(stack(dir: ttb, ..bases.map(b => line-box(1, align(center, b))))),
        ..if i == 0 { (axis-label(rowspan: 4, rotate(90deg, reflow: true)[Third letter]),) } else { () },
      )
    },
  )
}

#chart
