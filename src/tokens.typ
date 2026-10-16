// Design tokens shared with the Pencil design (design/png/*.png).
// Pencil frames are 1920×1080 px; the Typst page is 960×540 pt, so every
// Pencil pixel value is halved here.

#let palettes = (
  light: (
    bg: rgb("#F5F4F3"),
    surface: rgb("#EBE9E4"),
    ink: rgb("#1C1B18"),
    muted: rgb("#5C574A"),
    rule: rgb("#D1CFC8"),
    faint: rgb("#B9B5AB"),
    accent: rgb("#1348DC"),
    accent-2: rgb("#93CCDC"),
    accent-soft: rgb("#DCE5FB"),
    ok: rgb("#2F7D4F"),
    warn: rgb("#B7791F"),
    bad: rgb("#C0392B"),
  ),
  dark: (
    bg: rgb("#0F0E0C"),
    surface: rgb("#1A1916"),
    ink: rgb("#E9E7E1"),
    muted: rgb("#AAA599"),
    rule: rgb("#38352D"),
    faint: rgb("#4A463D"),
    accent: rgb("#54A2FF"),
    accent-2: rgb("#93CCDC"),
    accent-soft: rgb("#16223D"),
    ok: rgb("#5FBF86"),
    warn: rgb("#E0A84A"),
    bad: rgb("#F07167"),
  ),
)

// Latin face first, CJK fallback second (Source Han ships with most TeX/Linux
// setups; Noto CJK is the usual alternative name).
#let fonts = (
  serif: ("IBM Plex Serif", "Source Han Serif SC", "Noto Serif CJK SC"),
  sans: ("IBM Plex Sans", "Source Han Sans SC", "Noto Sans CJK SC"),
  mono: ("IBM Plex Mono", "Source Han Mono SC", "Noto Sans Mono CJK SC", "DejaVu Sans Mono"),
  // Geometric glyphs (■ □) are missing from Plex Mono; keep them half-width.
  glyph: ("DejaVu Sans Mono",),
)

#let sizes = (
  body: 14pt,
  small: 12pt,
  label: 10pt,
  chrome: 9pt,
  title: 28pt,
  kicker: 10pt,
)

// Letter-spacing of the mono labels (1px in Pencil).
#let tracking = 0.5pt

// Palette of the slide currently being laid out. Every slide updates it, so
// components can follow per-slide overrides (e.g. a dark closing slide).
#let palette-state = state("ascii-weekly-palette", palettes.light)
