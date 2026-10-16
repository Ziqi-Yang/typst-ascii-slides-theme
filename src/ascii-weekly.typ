// ascii-weekly — a Touying theme for weekly research-progress reports.
// Warm paper + IBM Plex (zed.dev) meets mono chrome and ASCII art (ascii.rest).
//
//   #import "@local/ascii-weekly:0.1.0": *
//   #show: ascii-weekly-theme.with(config-info(title: [...], ...))
//
// `= Section` makes a section slide (text right under it becomes its
// description), `== Title` starts a content slide.

#import "@preview/touying:0.8.0": *
#import "tokens.typ": *
#import "components.typ": *
#import "components.typ" as cw

// --- helpers ---------------------------------------------------------------------

#let _two(n) = if n < 10 { "0" + str(n) } else { str(n) }

// Plain text of a heading body, for breadcrumbs and kickers.
#let _plain(it) = {
  if it == none { "" } else if type(it) == str { it } else if it.has("text") { it.text } else if it.has(
    "children",
  ) { it.children.map(_plain).join() } else if it.has("body") { _plain(it.body) } else if it.func() == [ ].func() {
    " "
  } else { "" }
}

#let _slug(it) = lower(_plain(it).trim()).replace(regex("[^\p{L}\p{N}]+"), "-").trim("-")

// (index, total, heading) of the current level-1 heading; needs context.
#let _section() = {
  let all = query(heading.where(level: 1))
  let cur = utils.current-heading(level: 1)
  if cur == none { return (0, all.len(), none) }
  let i = all.position(h => h.location() == cur.location())
  (if i == none { 0 } else { i + 1 }, all.len(), cur)
}

#let _chrome-text(p, fill: auto, ..args) = text(
  font: fonts.mono,
  size: sizes.chrome,
  tracking: tracking,
  fill: if fill == auto { p.muted } else { fill },
  ..args,
)

// Hairline frame, `+` registration marks, header and footer — the page background.
#let _chrome(self) = {
  let p = self.store.palette
  let info = self.info
  let rule = 0.5pt + p.rule
  let (gx1, gx2, gy1, gy2) = (32pt, 927.5pt, 50pt, 490pt)
  place(top + left, dx: gx1, line(angle: 90deg, length: 540pt, stroke: rule))
  place(top + left, dx: gx2, line(angle: 90deg, length: 540pt, stroke: rule))
  place(top + left, dy: gy1, line(length: 960pt, stroke: rule))
  place(top + left, dy: gy2, line(length: 960pt, stroke: rule))
  for (x, y) in ((gx1, gy1), (gx2, gy1), (gx1, gy2), (gx2, gy2)) {
    place(top + left, dx: x - 4.5pt, dy: y, line(length: 9pt, stroke: 0.75pt + p.ink))
    place(top + left, dx: x, dy: y - 4.5pt, line(angle: 90deg, length: 9pt, stroke: 0.75pt + p.ink))
  }

  // header: ■ INSTITUTION / KIND ............ W42 · 2026.10.16
  let date = info.at("date", default: none)
  if type(date) == datetime { date = date.display("[year].[month].[day]") }
  let stamp = (info.at("week", default: none), date).filter(x => x != none)
  place(top + left, dx: 60pt, dy: 15pt, box(width: 840pt, height: 22pt, align(horizon, grid(
    columns: (1fr, auto),
    {
      box(width: 6pt, height: 6pt, fill: p.accent)
      h(7pt)
      _chrome-text(p, fill: p.ink, weight: "medium", upper(info.at("institution", default: none)))
      _chrome-text(p, fill: p.faint)[#h(7pt)/#h(7pt)]
      _chrome-text(p, upper(self.store.kind))
    },
    _chrome-text(p, stamp.join(" · ")),
  ))))

  // footer: ~/02-experiments ....... [■■■■□□□□] ....... 07 / 10
  place(top + left, dx: 60pt, dy: 500pt, box(width: 840pt, height: 22pt, align(horizon, context {
    let crumb = self.store.crumb
    if crumb == auto {
      let (i, _, h) = _section()
      crumb = if h == none { "~/" } else { "~/" + _two(i) + "-" + _slug(h.body) }
    }
    // Marginals see counters as of the page start, before Touying steps the
    // slide counter, so read it where the next page begins instead.
    let next = query(<touying-metadata>).find(m => (
      type(m.value) == dictionary and m.value.at("kind", default: none) == "touying-new-page" and m.location().page() > here().page()
    ))
    let n = if next == none { utils.slide-counter.final() } else { utils.slide-counter.at(next.location()) }.first()
    let total = calc.max(1, utils.last-slide-counter.final().first())
    grid(
      columns: (1fr, auto, 1fr),
      _chrome-text(p, crumb),
      ascii-bar(n / total, palette: p),
      align(right, _chrome-text(p, fill: p.ink, _two(n) + " / " + _two(total))),
    )
  })))
}

// Applies a slide's palette to its content.
#let _apply(self, body) = {
  let p = self.store.palette
  palette-state.update(p)
  set text(fill: p.ink)
  set raw(theme: if self.store.dark-slide { "code-dark.tmTheme" } else { "code-light.tmTheme" })
  body
}

#let _with-palette(self, dark) = {
  self.store.palette = if dark { palettes.dark } else { palettes.light }
  self.store.dark-slide = dark
  self
}

#let _page(self) = utils.merge-dicts(self, config-page(fill: self.store.palette.bg, background: _chrome(self)))

// --- slides -------------------------------------------------------------------

/// Content slide. Title and kicker come from the `== heading` and the current
/// section unless given. `crumb` overrides the footer path, `dark` flips this
/// one slide.
#let slide(
  title: auto,
  kicker: auto,
  crumb: auto,
  dark: auto,
  config: (:),
  repeat: auto,
  setting: body => body,
  composer: auto,
  ..bodies,
) = touying-slide-wrapper(self => {
  if dark != auto { self = _with-palette(self, dark) }
  if crumb != auto { self.store.crumb = crumb }
  self = _page(self)
  let heading-block = {
    let k = if kicker == auto {
      context {
        let (i, _, h) = _section()
        if h != none { "[ " + _two(i) + " ] " + upper(_plain(h.body)) }
      }
    } else { kicker }
    let t = if title == auto { utils.display-current-heading(level: 2, numbered: false) } else { title }
    block(spacing: 0pt, below: 26pt, stack(spacing: 12pt, if k != none { cw.kicker(k) }, {
      set par(leading: 0.42em)
      text(font: fonts.serif, size: sizes.title, t)
    }))
  }
  let new-setting = body => {
    show: _apply.with(self)
    v(12pt)
    if title != none { heading-block }
    show: setting
    body
  }
  touying-slide(self: self, config: config, repeat: repeat, setting: new-setting, composer: composer, ..bodies)
})

/// Cover slide. Reads `config-info`: title, subtitle, author, institution,
/// date, plus the theme's extras `report` (kicker), `advisor`, `period`, `week`.
/// `meta` overrides the key/value block, `art: none` drops the landscape.
#let title-slide(config: (:), meta: auto, art: auto, ..args) = touying-slide-wrapper(self => {
  self = _page(utils.merge-dicts(self, config))
  let info = self.info + args.named()
  let p = self.store.palette
  let rows = if meta == auto {
    (
      ("presenter", info.at("author", default: none)),
      ("advisor", info.at("advisor", default: none)),
      ("lab", info.at("institution", default: none)),
      ("period", info.at("period", default: none)),
    ).filter(r => r.at(1) != none)
  } else { meta }
  let lhs = block(height: 100%, inset: (top: 20pt, bottom: 10pt), {
    stack(
      spacing: 18pt,
      cw.kicker(info.at("report", default: "[ PROGRESS REPORT ]")),
      {
        set par(leading: 0.35em)
        text(font: fonts.serif, size: 42pt, info.title)
      },
      if info.at("subtitle", default: none) != none { text(size: 15pt, fill: p.muted, info.subtitle) },
    )
    v(1fr)
    grid(
      columns: (100pt, auto),
      column-gutter: 8pt,
      row-gutter: 11pt,
      ..rows.map(((k, v)) => (mono(k), text(font: fonts.mono, size: 11pt, fill: p.ink, v))).flatten(),
    )
  })
  let rhs = if art == auto { align(center + horizon, ascii-landscape()) } else { art }
  touying-slide(
    self: self,
    setting: body => _apply(self, body),
    grid(columns: (1fr, 320pt), column-gutter: 40pt, lhs, rhs),
  )
})

/// Agenda built from the level-1 headings, with dotted leaders and slide numbers.
#let agenda-slide(title: [This week at a glance], kicker: "[ 00 ] AGENDA", current: none, config: (:)) = touying-slide-wrapper(self => {
  self = _page(utils.merge-dicts(self, config, config-store(crumb: "~/00-agenda")))
  let p = self.store.palette
  let lhs = {
    stack(spacing: 16pt, cw.kicker(kicker), {
      set par(leading: 0.4em)
      text(font: fonts.serif, size: 32pt, title)
    }, ascii-rule(n: 22, size: 12pt))
  }
  let rhs = context {
    let hs = query(heading.where(level: 1))
    for (i, h) in hs.enumerate() {
      let on = current == i + 1
      block(width: 100%, inset: (y: 16pt), spacing: 0pt, stroke: (bottom: 0.5pt + p.rule), grid(
        columns: (auto, auto, 1fr, auto),
        column-gutter: 14pt,
        align: horizon,
        text(font: fonts.mono, size: 12pt, fill: if on { p.accent } else { p.muted }, "[" + _two(i + 1) + "]"),
        text(size: 16pt, weight: if on { "medium" } else { "regular" }, h.body),
        leader(),
        mono(size: 11pt, "p." + _two(utils.slide-counter.at(h.location()).first())),
      ))
    }
  }
  touying-slide(
    self: self,
    setting: body => _apply(self, body),
    pad(top: 20pt, grid(columns: (260pt, 1fr), column-gutter: 60pt, lhs, rhs)),
  )
})

/// Section divider: huge mono number, serif title, `====` rule, description.
#let section-slide(config: (:), body) = touying-slide-wrapper(self => {
  self = _page(utils.merge-dicts(self, config))
  let p = self.store.palette
  let content = context {
    let (i, total, h) = _section()
    grid(
      columns: (auto, 1fr),
      align: bottom,
      text(
        font: fonts.mono,
        size: 200pt,
        weight: "light",
        tracking: -10pt,
        top-edge: "cap-height",
        bottom-edge: "baseline",
        _two(i),
      ),
      pad(left: 40pt, bottom: 4pt, stack(
        spacing: 14pt,
        cw.kicker("[ SECTION " + _two(i) + " / " + _two(total) + " ]"),
        text(font: fonts.serif, size: 52pt, if h != none { h.body }),
        ascii-rule(n: 38, size: 14pt),
        if body != none and body != [] { text(fill: p.muted, body) },
      )),
    )
  }
  touying-slide(self: self, setting: b => _apply(self, align(bottom, b)), content)
})

/// One big statement. Follows the deck palette; `dark: true`/`false` overrides.
#let focus-slide(dark: auto, config: (:), body) = touying-slide-wrapper(self => {
  self = utils.merge-dicts(self, config)
  if dark != auto { self = _with-palette(self, dark) }
  self = _page(self)
  touying-slide(
    self: self,
    setting: b => _apply(self, align(center + horizon, text(font: fonts.serif, size: 40pt, b))),
    body,
  )
})

/// Closing slide with an ASCII horizon. Follows the deck palette;
/// `dark: true`/`false` overrides.
#let ending-slide(
  title: [Thanks.],
  kicker: "[ EOF ]",
  subtitle: [questions · comments · suggestions #h(6pt) → #h(6pt) Q&A],
  dark: auto,
  art: auto,
  config: (:),
) = touying-slide-wrapper(self => {
  self = utils.merge-dicts(self, config, config-store(crumb: "~/eof"))
  if dark != auto { self = _with-palette(self, dark) }
  self = _page(self)
  let ground = if art == auto {
    ascii-landscape(
      cols: 120,
      rows: 12,
      horizon: 0.35,
      far: none,
      sun: none,
      freq: (0.11, 0.045),
      amp: (2.2, 2.6),
      base: 0.25,
      slope: 0.08,
      max-density: 0.8,
      size: 11.5pt,
      fill: self.store.palette.faint,
    )
  } else { art }
  touying-slide(self: self, setting: b => _apply(self, b), {
    place(top + left, dx: 0pt, dy: 235pt, ground)
    pad(top: 30pt, align(center, stack(
      spacing: 18pt,
      cw.kicker(kicker),
      text(font: fonts.serif, size: 80pt, title),
      mono(size: 12pt, subtitle),
    )))
  })
})

// --- theme ------------------------------------------------------------------------

/// - dark (bool): dark terminal palette for the whole deck.
/// - kind (str): label after the institution in the header.
/// - section-slides (bool): emit a section slide for every `= heading`.
#let ascii-weekly-theme(dark: false, kind: "weekly report", section-slides: true, ..args, body) = {
  let p = if dark { palettes.dark } else { palettes.light }
  show: touying-slides.with(
    config-page(width: 960pt, height: 540pt, margin: (x: 60pt, top: 70pt, bottom: 70pt), fill: p.bg),
    config-common(
      slide-fn: slide,
      new-section-slide-fn: if section-slides { section-slide } else { none },
      receive-body-for-new-section-slide-fn: true,
      zero-margin-header: false,
      zero-margin-footer: false,
    ),
    config-methods(
      init: (self: none, body) => {
        set text(font: fonts.sans, size: sizes.body, fill: p.ink)
        set par(leading: 0.55em)
        set strong(delta: 200)
        show raw: set text(font: fonts.mono)
        set list(
          marker: context text(font: fonts.mono, fill: palette-state.get().accent, "—"),
          body-indent: 10pt,
          spacing: 20pt,
        )
        set enum(
          numbering: n => context text(font: fonts.mono, size: 0.85em, fill: palette-state.get().accent, "[" + _two(n) + "]"),
          body-indent: 10pt,
          spacing: 20pt,
        )
        set figure(supplement: [fig.], numbering: n => _two(n), gap: 8pt)
        show figure.caption: it => align(left, mono(size: sizes.chrome)[
          #it.supplement#context it.counter.display(it.numbering) — #it.body
        ])
        show link: it => context text(fill: palette-state.get().accent, underline(it))
        body
      },
      alert: (self: none, it) => text(fill: self.store.palette.accent, it),
    ),
    config-colors(primary: p.accent, neutral-lightest: p.bg, neutral-darkest: p.ink),
    config-store(palette: p, dark-slide: dark, kind: kind, crumb: auto),
    ..args,
  )
  body
}
