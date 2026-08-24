# MyCC — 编译器学习与开发仓库

这是仓库根目录的说明。**如果你（Claude）是在这一层被打开的，先看清楚用户要做哪部分。**

## 子项目

| 目录 | 内容 |
|---|---|
| `ocaml-learning/` | **OCaml 语言学习**（教学性质的连续问答）。有独立的 `CLAUDE.md`，规则和命令都在那里。 |
| `compiler-roadmap/` | **编译器的设计过程与设计结论**（路线规划 + 语言设计问答 + 决策记录）。**纯文档，没有代码。** 有独立的 `CLAUDE.md`。**和 OCaml 的教学进度是两回事，别混。** |
| `compiler/` | **编译器本体（代码）**。2026-08-21 建立，**目前是空壳** —— 还在设计阶段，动工条件写在它的 `README.md`。 |

## 如果用户要聊学习路线 / 课程选择 / 技能规划 / 语言设计

**先读 `compiler-roadmap/CLAUDE.md`** —— 那份有完整的接手顺序、当前状态快照和
「下次开工第一句话」，**照它走，别按下面这几行的老顺序自己摸**。

下面这几条是那份文件里最要紧的三个指针（**内容以那边为准**）：

- `skills-profile.md` —— **用户的技能栈档案。给任何学习建议之前必读。**
  他在 C / Linux 内核方向是**专家**（6 年内核源码阅读 + 一个类内核项目），
  在 C++ / OCaml / 编译器理论上是**初学者**。**按「平均水平」给建议会同时高估和低估他。**
- `ROADMAP.md` —— 路线本身。里面有「**明确排除的方向**」和「**已推翻的判断**」两节，
  **看完再提建议，别重复已经否决过的东西**（比如「实现 C 预处理器」「用 MIPS 做目标架构」）。
- `resources.md` —— 课程/书/工具清单，**每条都标了查证状态**（✅ 已查 / ⚠️ 未查证）。
  别把 ⚠️ 的当事实用。

**正在进行的语言设计讨论**在 `compiler-roadmap/notes/`：
`DESIGN-LOG.md`（每次对话一条）、`OPEN-QUESTIONS.md`（未决问题）、
`decisions/`（已经定死的，**别重新讨论**）。

## 如果用户要聊 OCaml 学习

**先读 `ocaml-learning/CLAUDE.md`，再读 `ocaml-learning/notes/PROGRESS.md`。**
那两个文件里有完整的教学约定、环境事实、构建命令和进度。不要按仓库根目录的默认习惯行事。

从仓库根目录调用 OCaml 的构建脚本时要带上子目录前缀：

```bash
bash ./ocaml-learning/scripts/ocaml.sh <子命令>
```

**这一条命令在两台机器上通用**——脚本自己识别平台，在 Windows 上会自动转进 WSL。
不要再手写 `wsl -d Ubuntu --` 前缀，那样只能在笔记本上跑。

**更推荐的做法是让用户直接把 `ocaml-learning/` 作为工作目录打开**，这样路径更短，
而且那一层的 `.claude/settings.json` 免授权规则会生效。

## 命令免授权（Agent 行为配置）

目前用的 Agent 只有 **Claude Code**。免授权白名单在 `.claude/settings.json` 的
`permissions.allow` 里，**两层各一份**，因为规则里的路径是相对工作目录的，不能互相照抄：

| 文件 | 何时生效 |
|---|---|
| `.claude/settings.json`（本层） | 把 `MyCC/` 作为工作目录打开 |
| `ocaml-learning/.claude/settings.json` | 把 `ocaml-learning/` 作为工作目录打开（**推荐**） |

**完整的机制说明、已放行/故意不放行的清单、加新规则的步骤，都在
`ocaml-learning/CLAUDE.md` 第 1.5 节**，这里不重复。

三条要点：

- `settings.json` 是**严格 JSON，写注释会让整个文件失效**——说明只能写在 CLAUDE.md 里
- **git 的写操作（commit/push/pull）故意没有放行**，弹框是「git 等用户开口」的最后一道闸
- 改之前**先读再合并**，别整体覆盖掉已有规则

## 交接自检

换机器或新对话后要验证上下文接没接上：在新对话里敲 **`/handoff-check`**。
两层都放了这个命令（根目录这份只是转发，真正的任务书在
`ocaml-learning/.claude/commands/handoff-check.md`）。
结果写进 `ocaml-learning/notes/handoff-report.md`。

## 多机同步

这个仓库通过 GitHub 在**两台交替使用**的开发机之间同步（远程 `08822407d/MyCC`）：

| 代号 | 机器 | 判据 |
|---|---|---|
| `win10-laptop` | Windows 10 笔记本，OCaml 装在 WSL2 里 | `ocaml.sh platform` 输出 `win-gitbash` 或 **`wsl`** |
| `ubuntu24-pc` | Ubuntu 24.04 台式机，原生 Linux | `ocaml.sh platform` 输出 `linux` |

> **2026-08-20：别再用会话的 `Platform:` 字段判断。**
> 笔记本的 VS Code 切到 WSL 远程模式之后，**它报的也是 `Platform: linux`**，
> 于是 `linux` 不再唯一对应台式机。
> 判据改成跑 `bash ./ocaml-learning/scripts/ocaml.sh platform`，
> 它靠 `/proc/version` 里有没有 `microsoft` 区分，不受编辑器模式影响。
> 详见 `ocaml-learning/CLAUDE.md` 第 0 节。

两台不会同时用。**涉及路径、磁盘、编辑器扩展等平台相关内容前，先确认在哪台机器上**，
细节见 `ocaml-learning/docs/env/`。

**进度记录（`ocaml-learning/notes/`）是跨机器传递状态的唯一载体，改完记得提交。**
但 **git 操作一律等用户开口**——不要主动 commit / push / pull。

OCaml 工具链本身**不在仓库里**（装在各机器的 `~/.opam`），换机器要照
`ocaml-learning/docs/SETUP-NEW-MACHINE.md` 装一遍。
