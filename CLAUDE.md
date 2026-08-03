# MyCC — 编译器学习与开发仓库

这是仓库根目录的说明。**如果你（Claude）是在这一层被打开的，先看清楚用户要做哪部分。**

## 子项目

| 目录 | 内容 |
|---|---|
| `ocaml-learning/` | **OCaml 语言学习**（教学性质的连续问答）。有独立的 `CLAUDE.md`，规则和命令都在那里。 |

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

## 交接自检

换机器或新对话后要验证上下文接没接上：在新对话里敲 **`/handoff-check`**。
两层都放了这个命令（根目录这份只是转发，真正的任务书在
`ocaml-learning/.claude/commands/handoff-check.md`）。
结果写进 `ocaml-learning/notes/handoff-report.md`。

## 多机同步

这个仓库通过 GitHub 在**两台交替使用**的开发机之间同步（远程 `08822407d/MyCC`）：

| 代号 | 机器 | 判据 |
|---|---|---|
| `win10-laptop` | Windows 10 笔记本，OCaml 装在 WSL2 里 | 会话环境 `Platform: win32` |
| `ubuntu24-pc` | Ubuntu 24.04 台式机，原生 Linux | 会话环境 `Platform: linux` |

两台不会同时用。**涉及路径、磁盘、编辑器扩展等平台相关内容前，先确认在哪台机器上**，
细节见 `ocaml-learning/docs/env/`。

**进度记录（`ocaml-learning/notes/`）是跨机器传递状态的唯一载体，改完记得提交。**
但 **git 操作一律等用户开口**——不要主动 commit / push / pull。

OCaml 工具链本身**不在仓库里**（装在各机器的 `~/.opam`），换机器要照
`ocaml-learning/docs/SETUP-NEW-MACHINE.md` 装一遍。
