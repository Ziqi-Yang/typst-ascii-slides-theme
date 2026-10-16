// Building blocks for weekly-report slides. Every component reads the active
// palette from `palette-state`, so it follows light/dark per slide.
#import "tokens.typ": *

#let _p() = palette-state.get()

// --- primitives ------------------------------------------------------------

/// Small mono label, the "chrome" voice of the theme.
#let mono(size: sizes.label, fill: auto, weight: "regular", tracking: tracking, body) = context text(
  font: fonts.mono,
  size: size,
  weight: weight,
  tracking: tracking,
  fill: if fill == auto { _p().muted } else { fill },
  body,
)

/// `[ 02 ] METHOD`-style kicker in the accent colour.
#let kicker(body) = context mono(fill: _p().accent, weight: "medium", body)

/// A row of `=` used under section titles (ascii.rest style).
#let ascii-rule(n: 38, char: "=", size: 14pt) = context text(
  font: fonts.mono,
  size: size,
  fill: _p().faint,
  char * n,
)

/// Surface-coloured pane with a hairline border, for figures.
#let pane(inset: (x: 20pt, y: 14pt), body) = context block(
  width: 100%,
  fill: _p().surface,
  stroke: 0.5pt + _p().rule,
  inset: inset,
  align(center + horizon, body),
)

/// `[■■■■■□□□□□]` progress bar.
#let ascii-bar(ratio, cells: 20, size: sizes.chrome, palette: auto) = context {
  let p = if palette == auto { _p() } else { palette }
  let n = int(calc.round(calc.clamp(ratio, 0, 1) * cells))
  text(font: fonts.mono, size: size, fill: p.faint)[\[]
  text(font: fonts.glyph, size: size, fill: p.ink, "■" * n)
  text(font: fonts.glyph, size: size, fill: p.faint, "□" * (cells - n))
  text(font: fonts.mono, size: size, fill: p.faint)[\]]
}

/// Dotted leader that fills the remaining line width.
#let leader() = context box(width: 1fr, repeat(gap: 0pt, text(font: fonts.mono, fill: _p().faint, "· ")))

// --- ASCII art ---------------------------------------------------------------

#let _ramp = " .:-=+*#%@"
#let _shade(v) = _ramp.at(int(calc.clamp(calc.round(v * 9), 0, 9)))

/// Generated ASCII landscape: rolling hills, optional far ridge and a shaded
/// sun drawn in the accent colour. Deterministic, so it renders the same every time.
///
/// - sun: `none` or `(col, row, radius)`.
#let ascii-landscape(
  cols: 40,
  rows: 30,
  horizon: 0.66,
  far: 0.5,
  sun: (26, 8, 3.6),
  max-density: 0.78,
  freq: (0.21, 0.08),
  amp: (2.0, 2.6),
  base: 0.36,
  slope: 0.06,
  size: 11pt,
  line-height: 1.2,
  fill: auto,
) = context {
  let p = _p()
  let ground = ()
  let glow = ()
  for r in range(rows) {
    let (a, b) = ("", "")
    for c in range(cols) {
      let h1 = rows * horizon + calc.sin(c * freq.at(0)) * amp.at(0) + calc.sin(c * freq.at(1) + 1.3) * amp.at(1)
      let h2 = if far == none { rows + 1 } else { rows * far + calc.sin(c * 0.13 + 2.1) * 2.4 }
      let d = if sun == none { 2 } else {
        let dx = (c - sun.at(0)) * 0.5
        let dy = r - sun.at(1)
        calc.sqrt(dx * dx + dy * dy) / sun.at(2)
      }
      let (ca, cb) = (" ", " ")
      if d < 1 {
        cb = _shade(0.3 + 0.7 * calc.sqrt(1 - d * d))
      } else if r > h1 {
        ca = _shade(calc.min(max-density, base + (r - h1) * slope + 0.08 * calc.sin(c * 0.7 + r)))
      } else if r > h2 {
        ca = _shade(calc.min(0.34, 0.12 + (r - h2) * 0.04))
      } else if calc.rem(c * c * 7 + r * 31 + c * r * 3, 29) == 0 {
        ca = "."
      }
      a += ca
      b += cb
    }
    ground.push(a)
    glow.push(b)
  }
  let layer(lines, color) = stack(..lines.map(l => box(
    height: size * line-height,
    text(font: fonts.mono, size: size, fill: color, l.replace(" ", "\u{00A0}")),
  )))
  box({
    layer(ground, if fill == auto { p.muted } else { fill })
    place(top + left, layer(glow, p.accent))
  })
}

// --- report blocks -------------------------------------------------------------

#let _status-kinds = (
  done: ("[x]", "ok"),
  doing: ("[~]", "accent"),
  todo: ("[ ]", "muted"),
  blocked: ("[!]", "bad"),
)

/// Checklist of tasks. Each item is `(kind, body)` or `(kind, body, meta)`,
/// with kind one of `done`, `doing`, `todo`, `blocked`.
#let status-list(..items) = context {
  let p = _p()
  block(width: 100%, stroke: (top: 0.5pt + p.rule), {
    for item in items.pos() {
      let (kind, body, ..rest) = item
      let (glyph, tone) = _status-kinds.at(kind)
      block(width: 100%, inset: (y: 15pt), spacing: 0pt, stroke: (bottom: 0.5pt + p.rule), grid(
        columns: (auto, 1fr, auto),
        column-gutter: 16pt,
        align: horizon,
        text(font: fonts.mono, size: 13pt, weight: "semibold", fill: p.at(tone), glyph),
        text(fill: if kind == "todo" { p.muted } else { p.ink }, body),
        mono(rest.at(0, default: none)),
      ))
    }
  })
}

/// Row of headline numbers. Items are dictionaries:
/// `(value: "3.1×", label: "less memory", arrow: "↓", tone: "accent", highlight: true)`.
#let metrics(..items) = context {
  let p = _p()
  let items = items.pos()
  block(width: 100%, stroke: (y: 0.5pt + p.rule), grid(
    columns: (1fr,) * items.len(),
    ..items.enumerate().map(((i, m)) => block(
      width: 100%,
      inset: (y: 12pt, left: if i == 0 { 0pt } else { 16pt }, right: 16pt),
      stroke: if i == 0 { none } else { (left: 0.5pt + p.rule) },
      stack(
        spacing: 12pt,
        {
          text(
            font: fonts.mono,
            size: 36pt,
            fill: if m.at("highlight", default: false) { p.accent } else { p.ink },
            m.value,
          )
          if "arrow" in m {
            h(7pt)
            text(font: fonts.mono, size: 15pt, fill: p.at(m.at("tone", default: "ok")), m.arrow)
          }
        },
        mono(m.label),
      ),
    )),
  ))
}

/// Hairline results table. `header` and every row are arrays of cells; the
/// first column is set in sans, the rest in right-aligned mono.
/// `highlight` is the 1-based index of the row to emphasise (e.g. "ours").
#let result-table(header: (), first-col: 280pt, highlight: none, ..rows) = context {
  let p = _p()
  let rows = rows.pos()
  let n = header.len()
  table(
    columns: (first-col,) + (1fr,) * (n - 1),
    stroke: (x, y) => (bottom: if y == 0 { 0.5pt + p.ink } else { 0.5pt + p.rule }),
    fill: (x, y) => if highlight != none and y == highlight { p.accent-soft },
    inset: (x, y) => (x: if x == 0 { 8pt } else { 12pt }, y: if y == 0 { 8pt } else { 11pt }),
    align: (x, y) => (if x == 0 { left } else { right }) + horizon,
    table.header(..header.map(h => mono(size: sizes.chrome, upper(h)))),
    ..rows
      .enumerate()
      .map(((i, row)) => {
        let hl = highlight != none and i + 1 == highlight
        row
          .enumerate()
          .map(((j, cell)) => if j == 0 {
            text(size: 13pt, weight: if hl { "semibold" } else { "regular" }, cell)
          } else {
            text(
              font: fonts.mono,
              size: 13pt,
              weight: if hl { "semibold" } else { "regular" },
              fill: if hl { p.accent } else { p.ink },
              cell,
            )
          })
      })
      .flatten(),
  )
}

#let _callout-kinds = (
  blocker: ("[!] BLOCKER", "bad"),
  question: ("[?] QUESTION", "accent"),
  note: ("[i] NOTE", "muted"),
  idea: ("[*] IDEA", "ok"),
)

/// Tagged box for blockers, questions and notes.
#let callout(kind: "note", title: none, body) = context {
  let p = _p()
  let (tag, tone) = _callout-kinds.at(kind)
  block(
    width: 100%,
    fill: p.surface,
    stroke: (top: 1.5pt + p.at(tone)),
    inset: (top: 12pt, x: 14pt, bottom: 14pt),
    stack(
      spacing: 13pt,
      mono(fill: p.at(tone), weight: "semibold", tag),
      if title != none { text(size: 15pt, weight: "medium", title) },
      {
        set par(leading: 0.6em)
        text(size: 12pt, fill: p.muted, body)
      },
    ),
  )
}

/// Lay several callouts (or any blocks) side by side.
#let side-by-side(gutter: 20pt, ..cells) = grid(
  columns: (1fr,) * cells.pos().len(),
  column-gutter: gutter,
  ..cells.pos(),
)

/// `→ decision needed  …` line under a hairline.
#let ask(label: "decision needed", body) = context {
  let p = _p()
  block(width: 100%, stroke: (top: 0.5pt + p.rule), inset: (top: 12pt), above: 26pt, {
    mono(fill: p.accent, weight: "medium", "→ " + label)
    h(8pt)
    text(size: 12pt, fill: p.muted, body)
  })
}

/// TODO / DOING / DONE board. Each column is an array of cards, a card is
/// `(title, meta)` or just `title`.
#let kanban(todo: (), doing: (), done: ()) = context {
  let p = _p()
  let column(name, tone, cards) = {
    block(width: 100%, inset: (bottom: 6pt), stroke: (bottom: 1pt + p.at(tone)), spacing: 8pt, grid(
      columns: (1fr, auto),
      mono(fill: p.at(tone), weight: "semibold", name), mono("(" + str(cards.len()) + ")"),
    ))
    for card in cards {
      let (title, meta) = if type(card) == array { (card.at(0), card.at(1, default: none)) } else { (card, none) }
      block(width: 100%, fill: p.surface, stroke: 0.5pt + p.rule, inset: (y: 12pt, x: 12pt), spacing: 8pt, stack(
        spacing: 9pt,
        text(size: 13pt, fill: if name == "DONE" { p.muted } else { p.ink }, title),
        if meta != none { mono(size: sizes.chrome, meta) },
      ))
    }
  }
  grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 20pt,
    column("TODO", "muted", todo), column("DOING", "accent", doing), column("DONE", "ok", done),
  )
}

/// Annotations next to code: `(ref, body)` pairs, e.g. `("L4–5", [band of width 1])`.
#let notes-list(..items) = context {
  let p = _p()
  stack(spacing: 22pt, ..items.pos().map(((r, body)) => stack(
    spacing: 8pt,
    mono(fill: p.accent, weight: "medium", "→ " + r),
    text(size: 12pt, fill: p.muted, body),
  )))
}

/// Zed-like editor window around a raw block: tab bar plus line numbers.
#let code-window(file: none, tabs: (), size: 11pt, body) = context {
  let p = _p()
  let tab(name, active) = box(
    inset: (x: 11pt, y: 6pt),
    fill: if active { p.bg } else { none },
    stroke: (right: 0.5pt + p.rule),
    {
      if active {
        box(width: 4pt, height: 4pt, fill: p.accent, baseline: -1.5pt)
        h(5pt)
      }
      text(font: fonts.mono, size: sizes.chrome, fill: if active { p.ink } else { p.muted }, name)
    },
  )
  block(width: 100%, fill: p.surface, stroke: 0.5pt + p.rule, clip: true, {
    block(width: 100%, stroke: (bottom: 0.5pt + p.rule), spacing: 0pt, {
      if file != none { tab(file, true) }
      for t in tabs { tab(t, false) }
    })
    block(width: 100%, inset: (y: 12pt), spacing: 0pt, {
      show raw: set text(font: fonts.mono, size: size)
      show raw.where(block: true): set par(leading: 0.9em)
      show raw.line: it => {
        box(width: 30pt, align(right, text(fill: p.faint, str(it.number))))
        h(14pt)
        it.body
      }
      body
    })
  })
}
