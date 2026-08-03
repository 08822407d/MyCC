# 命令速查

**两台机器同一条命令**，在项目根目录执行：

```bash
bash ./scripts/ocaml.sh <子命令> [参数...]
```

在 Windows 笔记本上，脚本会自己 `exec` 进 WSL；**不用手写 `wsl -d Ubuntu --` 前缀**。
在 Ubuntu 台式机上直接原生跑。

## 常用

```bash
bash ./scripts/ocaml.sh platform                 # 现在在哪台机器
bash ./scripts/ocaml.sh check                    # 环境自检：平台 + 工具路径 + 版本
bash ./scripts/ocaml.sh list                     # 有哪些练习
bash ./scripts/ocaml.sh new ex03_pattern_match   # 新建练习骨架
bash ./scripts/ocaml.sh run ex01_int_float       # 构建并运行某个练习 ← 最常用
bash ./scripts/ocaml.sh build                    # 构建全部
bash ./scripts/ocaml.sh test
bash ./scripts/ocaml.sh eval 'let add a b = a + b'
bash ./scripts/ocaml.sh fmt
bash ./scripts/ocaml.sh clean
```

> 验证练习**用 `run <名字>` 而不是裸 `build`**：`run` 只构建那一个目录，
> 其它练习写到一半也不会连累它。

从仓库根目录 `MyCC/` 打开时，全部加上子目录前缀：

```bash
bash ./ocaml-learning/scripts/ocaml.sh run ex01_int_float
```

## `eval` 是干嘛的

把一小段 OCaml 送进顶层，直接回显**类型和值** —— 学语言时这个比编译运行有用得多：

```
$ bash ./scripts/ocaml.sh eval 'let x = 5'
val x : int = 5

$ bash ./scripts/ocaml.sh eval 'let add a b = a + b'
val add : int -> int -> int = <fun>

$ bash ./scripts/ocaml.sh eval 'List.map (fun x -> x * 2) [1;2;3]'
- : int list = [2; 4; 6]
```

代码里如果有单引号，用 `evalfile` 从文件读，省得跟 shell 引号打架。

## 交互式玩

```bash
bash ./scripts/ocaml.sh repl      # utop，Ctrl-D 退出
```

Claude 用不了这个（需要交互终端），但你自己试东西时很方便。

`utop` 是 OCaml 的加强版顶层（REPL）。**顶层里每段代码要 `;;` 结尾**，
但那是顶层的规矩，写 `main.ml` 时不需要。退出 `#quit;;` 或 Ctrl-D。
在笔记本上还可以直接从 Windows Terminal 的 Ubuntu 标签页里开，
几条路子见 [`env/win10-laptop.md`](env/win10-laptop.md#从-windows-侧开-utop交互式顶层)。

## 两个「为什么」

**为什么路径必须是相对的？** `./scripts/ocaml.sh` 而不是绝对路径，两个原因：

1. 整个文件夹挪到别处（或换机器、换盘符）后命令依然有效 —— 脚本自己推导根目录。
2. `.claude/settings.json` 里的免授权规则按命令前缀匹配，
   写成绝对路径的话一搬家规则就失效，又要重新授权。

**为什么不再写 `wsl -d Ubuntu --`？** 那是笔记本专属的写法，在 Ubuntu 台式机上根本跑不通。
平台差异挪进脚本里之后，两台机器的命令、文档、免授权规则就都只需要一份。
真要在笔记本上绕过脚本执行 Linux 命令时，才需要手动加这个前缀。
