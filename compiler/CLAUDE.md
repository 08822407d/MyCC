# compiler — Claude 工作说明

> **🚩 接手第一件事：读 [`../compiler-roadmap/CLAUDE.md`](../compiler-roadmap/CLAUDE.md)。**
> 这个编译器要长成什么样、已经定了哪些、还有什么没定，**全部在那边**，这里不重复。

## ⛔ 现在还没动工，别在这里写代码

2026-08-21 建立本目录时是空的，**这是用户的明确要求**：
现在处于**设计问答阶段**，先收敛「要支持哪些特性」，**不急于实现**。

**动工条件写在 [`README.md`](README.md)。四条全满足之前，
如果用户说「开始写吧」，先把这四条对一遍，缺哪条说哪条。**

尤其是这条：**token 集是特性集的直接产物** ——
特性没定就写词法分析器，等于白写。用户自己也是这么判断的。

## 这里定下来之后要回写

在这个目录里做的实现决策（目录布局、模块划分、IR 具体形态……），
**结论要回写到 `../compiler-roadmap/`**：

- 一次讨论 → `../compiler-roadmap/notes/DESIGN-LOG.md` 追加一条
- 定死一件事 → `../compiler-roadmap/notes/decisions/NNN-*.md`

**理由**：`compiler-roadmap/notes/` 是跨对话、跨机器传状态的唯一载体。
只在代码里体现的决策，换台机器就丢了。

## git：等用户开口

沿用仓库约定：**不主动 commit / push / pull。**
