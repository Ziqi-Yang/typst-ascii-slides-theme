// 中文示例：与 template/main.typ 相同的版式，内容为中文。
//   typst compile --font-path ../fonts zh.typ zh-light.pdf
//   typst compile --font-path ../fonts --input dark=true zh.typ zh-dark.pdf
#import "@local/ascii-weekly:0.1.0": *

#let dark = sys.inputs.at("dark", default: "false") == "true"

#show: ascii-weekly-theme.with(
  dark: dark,
  kind: "组会周报",
  section-slides: false,
  config-info(
    title: [长文档 OCR 中的 \ 稀疏注意力],
    subtitle: [Sparse Attention for Long-Document OCR · 本周训练与评测进展],
    author: [张三],
    advisor: [李四 教授],
    institution: [ABC institution],
    report: [\[ 进展汇报 · 第 07 期 \]],
    week: "W42",
    date: datetime(year: 2026, month: 10, day: 16),
    period: [2026.10.09 → 2026.10.16],
  ),
)
#set text(lang: "zh", region: "cn")

#title-slide(meta: (
  ("汇报人", [张三]),
  ("导师", [李四 教授]),
  ("单位", [ABC institution]),
  ("周期", [2026.10.09 → 10.16]),
))

#agenda-slide(title: [本周概览], current: 2)

= 本周小结

== 稀疏注意力在精度不降的前提下，显存减少 3.1 倍

#status-list(
  ("done", [在 FlashAttention-2 内核中重新实现块稀疏掩码], "完成 · 10.12"),
  ("done", [完成 DocVQA-long 在 4k / 8k / 16k 上下文的完整评测], "完成 · 10.14"),
  ("doing", [消融实验：全局 token 数量（8 → 64）], "3 / 5 组"),
  ("blocked", [32k 上下文下 batch size > 1 时显存溢出], "受阻"),
  ("todo", [为 workshop 论文撰写相关工作一节], "下周"),
)

= 实验

#section-slide[长篇扫描文档上的稀疏注意力与稠密注意力对比 —— 实验设置、运行情况与遇到的问题。]

== 块稀疏注意力：局部窗口 + 少量全局 token

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

#slide(kicker: "[ 02 ] 方法", composer: (1fr, 340pt))[
  #v(6pt)
  - 每个 64-token 的块只关注自身及左右相邻的 2 个块
  - 16 个全局 token（版面锚点）可以看到所有块
  - 掩码按页构建一次，在各层之间复用
  - 可直接替换稠密 ViT 编码器，解码器无需重新训练
][
  #figure(
    pane({
      set par(leading: 0.42em)
      mono(size: 8.5pt, tracking: 0pt, mask)
    }),
    caption: [注意力掩码（\# 全局，+ 局部，· 跳过）],
  )
]

= 结果

== 精度持平，显存只需三分之一

#metrics(
  (value: "+0.4", label: "ANLS 相比稠密基线", arrow: "↑", tone: "ok"),
  (value: "3.1×", label: "16k 下显存节省", arrow: "↓", tone: "accent", highlight: true),
  (value: "1.8×", label: "推理加速", arrow: "↑", tone: "ok"),
)
#v(14pt)
#result-table(
  header: ("模型", "上下文", "ANLS", "显存 (GB)", "tok/s"),
  highlight: 3,
  ([稠密 ViT-L（基线）], "16k", "71.2", "38.4", "412"),
  ([Longformer 式], "16k", "69.8", "15.1", "690"),
  ([块稀疏（本文）], "16k", "71.6", "12.3", "745"),
)

== 整个掩码只需十行 PyTorch

#slide(kicker: "[ 04 ] 实现", composer: (560pt, 1fr))[
  #code-window(file: "sparse_mask.py", tabs: ("train.py",))[
    ```python
    def build_mask(n_blocks, window=1, n_global=16):
        """块稀疏掩码：局部窗口 + 全局 token。"""
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
    ("L4–5", [宽度为 1 的带状区域 → 相邻 3 个块]),
    ("L7–9", [全局行与列；锚点为前 16 个版面 token]),
    ("L10", [布尔或运算，直接送入 FlashAttention 的块掩码]),
  )
]

#speaker-note[提一下：掩码按页缓存。]

= 问题与讨论

== 有两件事想听听您的意见

#side-by-side(
  callout(kind: "blocker", title: [32k 上下文在 batch > 1 时显存溢出])[
    目前解码器的激活显存占主导。梯度检查点有效，但吞吐下降约 35%。
  ],
  callout(kind: "question", title: [投稿目标选哪个会议？])[
    结果已够 workshop 水平。ICDAR'27（截稿 01.15）是否现实，还是等完整消融再投？
  ],
  callout(kind: "note", title: [集群配额 10.20 重置])[
    已排队 3 组消融实验，周一开跑，预计周三完成。
  ],
)
#ask(label: "需要决定")[投稿会议，请在 10.23（周四）前确定 —— 以便规划消融实验预算]

= 下周计划

== W43 计划：完成消融，开始写作

#kanban(
  todo: (([撰写相关工作], "写作 · 2 天"), ([用新分词器重跑基线], "实验 · 4 小时")),
  doing: (([全局 token 消融（8→64）], "3 / 5 组"), ([分块解码器修复 32k 溢出], "调试")),
  done: (([稀疏内核 + 单元测试], "已合并 #41"), ([DocVQA-long 4k/8k/16k 评测], "已记录")),
)

#ending-slide(title: [谢谢], subtitle: [提问 · 意见 · 建议 #h(6pt) → #h(6pt) Q&A])
