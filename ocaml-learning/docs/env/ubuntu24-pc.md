# ubuntu24-pc — Ubuntu 24.04 台式机（家里）

会话环境信息里 `Platform: linux` 就是这台。通用部分见 [`COMMON.md`](COMMON.md)。

## 状态：**已核对（2026-08-05）**，环境可用

`bash ./scripts/ocaml.sh check` + `run ex00_smoke` 都跑过，冒烟输出 `hello`。
下面是实测事实，可以直接当依据用。

## ⚠️ 只在本机成立

- **原生 Linux，没有 WSL。** 不存在 `wsl -d Ubuntu --` 这种前缀，
  也不存在 `/mnt/d` 跨文件系统的性能问题。看到任何带 `wsl` 的命令就是拿错平台了。
- 仓库路径：`/home/cheyh/projs/MyCC`，本项目在 `/home/cheyh/projs/MyCC/ocaml-learning`。
  在 Linux 原生盘上，没有性能问题。
- **opam switch 名叫 `default`，不叫 `5.5.0`** —— 和 COMMON.md 的口径不一样，
  但那只是**名字**不同，编译器本身确实是 5.5.0。工具在 `~/.opam/default/bin/`，
  不在 `/usr/bin`，所以 COMMON.md 的坑 1 在这台机器上没踩到。**不要因为名字不一致就去重建 switch。**
- `opam` 本体装在 `~/.local/bin/opam`（2.5.2），不是 apt 装的。
- **没有叫 `toylang` 的目录**。但有一个同类的参考项目：
  **`~/projs/ocaml-compiler-lab`**（2026-07-27 建的），实现了一个极小表达式语言 `calc`，
  链路是 `lexer.mll`(ocamllex) → `parser.mly`(menhir) → `ast.ml` → `interp.ml` 树遍历求值，
  支持整数、`+ - * /`、一元负号、括号、以及 **`let x = e1 in e2`（含嵌套与遮蔽）**。
  → 教到 `let` 作用域、AST、模式匹配时，**这个项目就是现成的教具**。

## 版本核对结果（2026-08-05，对照 [`COMMON.md`](COMMON.md)）

| 组件 | COMMON.md 口径 | 本机实测 | 结论 |
|---|---|---|---|
| OCaml | 5.5.0 | 5.5.0 | ✅ |
| dune | 3.24.x | 3.24.1 | ✅ |
| opam | 2.5 以上 | 2.5.2 | ✅ |
| ocaml-lsp-server | 1.27.x | 1.27.0 | ✅ |
| utop | 2.17.x | 2.17.0 | ✅ |
| ocamlformat | 0.29.x | 0.29.0 | ✅ |
| menhir | 20260209 | 20260209 | ✅ |
| opam switch 名 | `5.5.0` | `default` | ⚠️ 只是名字不同，无需处理 |

`ocamllex` / `ocamllsp` 也都在。**两台机器版本一致，不需要对齐。**

## 汇编 / 链接工具链（2026-08-05 实测，跟着公开课做要用）

伯克利那门课的玩具编译器要调 `nasm` + `gcc` 把汇编跑起来。本机都装着：

| 工具 | 路径 |
|---|---|
| nasm | `/usr/bin/nasm` |
| gcc | `/usr/bin/gcc` |
| ld | `/usr/bin/ld` |

`uname -m` = **`x86_64`**。

⚠️ **课上的 `-f macho64` 是 macOS 的目标格式（讲师在 Mac 上），本机必须改成 `-f elf64`。**

改完整条链路实测跑通（源码 → 汇编 → 链接 → 执行 → 抓输出）。
**完整配方在 [`../../notes/concepts/07-toy-compiler-pipeline.md`](../../notes/concepts/07-toy-compiler-pipeline.md)**，
含要自己补的 `runtime.c`、dune 的 `(libraries unix)`、以及 `.note.GNU-stack` 那个坑。

## 重新核对的办法

```bash
bash ./scripts/ocaml.sh check          # 平台 + 工具路径 + 8 项版本
bash ./scripts/ocaml.sh run ex00_smoke # 应输出 hello
```

## 如果 check 直接失败

说明环境其实没装好，照 [`SETUP-NEW-MACHINE.md`](../SETUP-NEW-MACHINE.md) 的
**原生 Linux 分支**走一遍。

## 命令

和笔记本上一模一样，没有前缀：

```bash
bash ./scripts/ocaml.sh run ex01_int_float
```

## VS Code

原生 Linux 直接装 `ocamllabs.ocaml-platform` 即可，
**不需要** remote-wsl（那是笔记本那台才需要的）。
