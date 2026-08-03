# OCaml 学习

学 OCaml，目标是拿它做编译器设计与开发的练习。
本目录是仓库 [MyCC](https://github.com/08822407d/MyCC) 的一个子项目，用于**两台机器交替学习**时同步进度。

## 快速开始（两台机器同一条命令）

```bash
bash ./scripts/ocaml.sh check                  # 环境自检：平台 + 工具版本
bash ./scripts/ocaml.sh run ex00_smoke         # 应输出 hello
bash ./scripts/ocaml.sh eval 'let x = 5'       # val x : int = 5
```

Windows 笔记本上脚本会自己转进 WSL，**不用手写 `wsl -d Ubuntu --`**；
Ubuntu 台式机上原生跑。命令速查见 [`docs/COMMANDS.md`](docs/COMMANDS.md)。

## 怎么做练习

Claude 会把整道题准备好，你只需要：

1. 打开它给的那个 `exercises/exNN_xxx/main.ml`
2. 只改文件顶部「你的代码」那一段（分隔线以下别动）
3. 说一声「好了」，Claude 自动构建运行并反馈自测结果

不用建文件夹、不用改 dune、不用记命令。约定见 [`docs/EXERCISE-FORMAT.md`](docs/EXERCISE-FORMAT.md)。

## 目录

| 位置 | 放什么 |
|---|---|
| `CLAUDE.md` | Claude 的工作说明 + **当前进度快照**。对话丢了就从这里恢复。 |
| `notes/PROGRESS.md` | 教到哪了（详细） |
| `notes/MASTERY.md` | 掌握程度的客观观察记录 |
| `notes/concepts/` | 每个知识点一篇小笔记 |
| `exercises/` | 练习代码，一道题一个子目录 |
| `scratch/` | 临时验证代码，可随时清空 |
| `scripts/ocaml.sh` | 唯一的构建/运行入口（自带平台识别） |
| `docs/ENVIRONMENT.md` | **环境索引 + 怎么判断当前在哪台机器** |
| `docs/env/` | 平台相关内容：`COMMON.md` / `win10-laptop.md` / `ubuntu24-pc.md` |
| `docs/EXERCISE-FORMAT.md` | 练习题的组织约定 |
| `docs/COMMANDS.md` | 命令速查 |
| `docs/HANDOFF-CHECK.md` | **换机器/新对话后，验证上下文有没有接上**（敲 `/handoff-check` 自动跑） |
| `.claude/commands/` | slash command，目前只有 `/handoff-check` |
| `docs/SETUP-NEW-MACHINE.md` | 在一台新机器上装环境 |
| `.claude/settings.json` | 免授权命令白名单 |

## 两台机器

| 代号 | 机器 | 判据 |
|---|---|---|
| `win10-laptop` | Windows 10 笔记本，OCaml 在 WSL2 里 | 会话环境 `Platform: win32` |
| `ubuntu24-pc` | Ubuntu 24.04 台式机，原生 Linux | 会话环境 `Platform: linux` |

交替使用，不会同时用。**工具链本身不在仓库里**（装在各机器的 `~/.opam`），
新机器照 `docs/SETUP-NEW-MACHINE.md` 装一遍。

## 这个文件夹可以随便挪

所有路径都由脚本自己推导，免授权规则也用的相对路径。挪完之后：

1. 用 VS Code / Claude Code 打开新位置
2. 跑一次 `bash ./scripts/ocaml.sh run ex00_smoke` 确认工具链还通
3. Claude 会自动读 `CLAUDE.md` + `notes/PROGRESS.md` 接上进度
