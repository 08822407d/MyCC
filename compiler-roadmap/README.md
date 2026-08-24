# 编译器设计

设计一门语言 + 它的编译器。**这个目录只放文档：设计过程 + 设计结论。**
代码在 [`../compiler/`](../compiler/)，OCaml 学习在 [`../ocaml-learning/`](../ocaml-learning/)。

本目录是仓库 [MyCC](https://github.com/08822407d/MyCC) 的一个子项目，
通过 git 在**两台交替使用的开发机**之间同步。

## 现在在哪一步

**设计问答阶段（背景地图）** —— 还没写任何代码，这是有意为之。

| | |
|---|---|
| 实现语言 | **OCaml** |
| 源语言 | **C 子集 + 自选扩展**（以 C 为底，自己决定砍什么、加什么） |
| 预处理器 | **不做**，用现成的 `gcc -E` |
| 特性集 | ⬜ **未决** —— 这正是当前要收敛的东西 |

详细状态见 [`CLAUDE.md`](CLAUDE.md) 的「当前状态快照」。

## 目录

| 位置 | 放什么 |
|---|---|
| `CLAUDE.md` | Claude 的工作说明 + **当前状态快照**。对话丢了从这里恢复 |
| `ROADMAP.md` | 学习路线（阶段 0–5）+ **明确排除的方向** + **已推翻的判断** |
| `skills-profile.md` | 技能栈档案。**给任何学习建议之前必读** |
| `resources.md` | 课程/书/工具清单，**每条标了查证状态**（✅ 已查 / ⚠️ 未查证） |
| `notes/DESIGN-LOG.md` | **每次设计对话一条**：谈了什么、结论、遗留 |
| `notes/OPEN-QUESTIONS.md` | 未决问题清单 |
| `notes/decisions/` | 定死的决策，一条一篇（`INDEX.md` 是总表） |
| `notes/feature-inventory.md` | 特性 ↔ 编译器机制映射表（**特性取舍的判据**） |
| `notes/survey/` | 「背景地图」阶段的资料调研，一个专题一篇 |
| `notes/glossary.md` | 编译器术语表 |
| `docs/DOC-CONVENTIONS.md` | 各类记录的体例约定 |
| `spec/` | 语言规范/架构的**定稿**（还空着） |
| `scratch/` | 临时验证，可随时清空 |

## 怎么接着上次的讨论

新对话 / 换机器之后，读这三样就能续上：

1. `CLAUDE.md`（顶部的「下次开工第一句话」+ 状态快照）
2. `notes/DESIGN-LOG.md` 的**最后一条**
3. `notes/OPEN-QUESTIONS.md`

**`notes/` 是跨机器传状态的唯一载体，讨论完记得提交。**
