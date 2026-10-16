#import "@local/ascii-weekly:0.1.0": *

// `typst compile --input dark=true ...` for the dark deck.
#let dark = sys.inputs.at("dark", default: "false") == "true"

#show: ascii-weekly-theme.with(
  dark: dark,
  section-slides: false,
  config-info(
    title: [Sparse Attention for Long-Document OCR],
    subtitle: [长文档 OCR 中的稀疏注意力 — weekly update on training & eval],
    author: [Your Name],
    advisor: [Prof. Advisor],
    institution: [ABC institution],
    report: [\[ PROGRESS REPORT · NO.07 \]],
    week: "W42",
    date: datetime(year: 2026, month: 10, day: 16),
    period: [2026.10.09 → 2026.10.16],
  ),
)

#title-slide()

#agenda-slide(current: 2)

= TL;DR

== Sparse attention matches dense accuracy at 3.1× less memory

#status-list(
  ("done", [Re-implemented block-sparse mask in FlashAttention-2 kernel], "done · 10.12"),
  ("done", [Full DocVQA-long eval for 4k / 8k / 16k context], "done · 10.14"),
  ("doing", [Ablation: global-token count (8 → 64)], "3 / 5 runs"),
  ("blocked", [OOM on 32k context with batch size > 1], "blocked"),
  ("todo", [Write related-work section for the workshop draft], "next week"),
)

= Experiments

#section-slide[Sparse vs. dense attention on long scanned documents — setup, runs, and what broke.]

== Block-sparse attention keeps local windows + a few global tokens

#let mask = {
  let n = 24
  range(n)
    .map(r => range(n)
      .map(c => {
        if r < 2 or c < 2 { "#" } else if calc.abs(calc.floor(r / 3) - calc.floor(c / 3)) <= 1 { "+" } else { "·" }
      })
      .join(" "))
    .join("\n")
}

#slide(kicker: "[ 02 ] METHOD", composer: (1fr, 340pt))[
  #v(6pt)
  - Each 64-token block attends to itself and its 2 neighbours
  - 16 global tokens (layout anchors) see every block
  - Mask is built once per page, reused across layers
  - Drop-in for the dense ViT encoder — no retraining of the decoder
][
  #figure(
    pane({
      set par(leading: 0.42em)
      mono(size: 8.5pt, tracking: 0pt, mask)
    }),
    caption: [attention mask (\# global, + local, · skipped)],
  )
]

= Results

== Same accuracy, a third of the memory

#metrics(
  (value: "+0.4", label: "ANLS vs. dense", arrow: "↑", tone: "ok"),
  (value: "3.1×", label: "less GPU memory @16k", arrow: "↓", tone: "accent", highlight: true),
  (value: "1.8×", label: "faster inference", arrow: "↑", tone: "ok"),
)
#v(14pt)
#result-table(
  header: ("model", "ctx", "ANLS", "mem (GB)", "tok/s"),
  highlight: 3,
  ([Dense ViT-L (baseline)], "16k", "71.2", "38.4", "412"),
  ([Longformer-style], "16k", "69.8", "15.1", "690"),
  ([Block-sparse (ours)], "16k", "71.6", "12.3", "745"),
)

== The whole mask is ten lines of PyTorch

#slide(kicker: "[ 04 ] IMPLEMENTATION", composer: (560pt, 1fr))[
  #code-window(file: "sparse_mask.py", tabs: ("train.py",))[
    ```python
    def build_mask(n_blocks, window=1, n_global=16):
        """Block-sparse mask: local window + global."""
        idx = torch.arange(n_blocks)
        dist = (idx[:, None] - idx[None, :]).abs()
        local = dist <= window

        glob = torch.zeros_like(local)
        glob[:n_global, :] = True
        glob[:, :n_global] = True
        return local | glob
    ```
  ]
][
  #v(4pt)
  #notes-list(
    ("L4–5", [band of width 1 → 3 neighbouring blocks]),
    ("L7–9", [global rows + cols; anchors are the first 16 layout tokens]),
    ("L10", [boolean OR, fed straight to FlashAttention's block mask]),
  )
]

#speaker-note[Mention that the mask is cached per page.]

= Blockers

== Two things I'd like your input on

#side-by-side(
  callout(kind: "blocker", title: [32k context OOMs at batch > 1])[
    Activation memory of the decoder dominates now. Gradient checkpointing helps but costs 35% throughput.
  ],
  callout(kind: "question", title: [Which venue should we target?])[
    Results are workshop-ready. Is ICDAR'27 (deadline 01.15) realistic, or wait for the full ablation?
  ],
  callout(kind: "note", title: [Cluster quota resets on 10.20])[
    Queued 3 ablation runs to start Monday; ETA Wednesday.
  ],
)
#ask[target venue, by Thu 10.23 — so I can plan the ablation budget]

= Next week

== Plan for W43: finish ablations, start writing

#kanban(
  todo: (([Related-work section], "writing · 2d"), ([Rerun baseline w/ new tokenizer], "exp · 4h")),
  doing: (([Global-token ablation (8→64)], "3 / 5 runs"), ([Fix 32k OOM via chunked decoder], "debug")),
  done: (([Sparse kernel + unit tests], "merged #41"), ([DocVQA-long eval @ 4k/8k/16k], "logged")),
)

#ending-slide()
