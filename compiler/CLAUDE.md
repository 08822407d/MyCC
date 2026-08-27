# compiler — Claude 工作说明

> **🚩 接手第一件事：读 [`../compiler-roadmap/CLAUDE.md`](../compiler-roadmap/CLAUDE.md)。**
> 这个编译器要长成什么样、已经定了哪些、还有什么没定，**全部在那边**，这里不重复。

## 当前状态（2026-08-27）

~~⛔ 现在还没动工，别在这里写代码~~ ——
**词法分析器已于 2026-08-27 实现完成**（用户 2026-08-26 明确开口
「按 spec/lexer/DESIGN.md 开始实现」）。

| 已有 | 说明 |
|---|---|
| `lib/lexer/` | C17 词法分析器（ocamllex + menhir `--only-tokens`），设计见 `../compiler-roadmap/spec/lexer/DESIGN.md` |
| `bin/main.ml` | token 转储 CLI：`dune exec bin/main.exe -- [-l] file.i` |
| `test/run.sh` | 验收 T0/T1/T2（决策 008）：`bash test/run.sh`，2026-08-27 全过（21/21） |

**parser 及之后的层仍未动工** —— `README.md` 的动工条件对它们继续有效
（特性集未收敛、决策 004 暂定、LLVM 未装）。

~~尤其是这条：token 集是特性集的直接产物——特性没定就写词法分析器，等于白写~~
（2026-08-26 修正：对完整 C17 词法不成立，见 README 动工条件 1 与决策 005）。

## 这里定下来之后要回写

在这个目录里做的实现决策（目录布局、模块划分、IR 具体形态……），
**结论要回写到 `../compiler-roadmap/`**：

- 一次讨论 → `../compiler-roadmap/notes/DESIGN-LOG.md` 追加一条
- 定死一件事 → `../compiler-roadmap/notes/decisions/NNN-*.md`

**理由**：`compiler-roadmap/notes/` 是跨对话、跨机器传状态的唯一载体。
只在代码里体现的决策，换台机器就丢了。

## git：等用户开口

沿用仓库约定：**不主动 commit / push / pull。**
