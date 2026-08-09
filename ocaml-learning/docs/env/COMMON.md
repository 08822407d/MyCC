# 两台机器都成立的环境事实

只放**跟具体机器无关**的内容。任何带盘符、带 `~/` 具体路径、带 vhdx 的，
都属于单机文档，不要写在这里。

## 版本口径

两台机器**都以这一套为准**，装环境时照抄：

| 组件 | 版本 |
|---|---|
| opam | 2.5 以上 |
| OCaml | 5.5.0（opam switch 名就叫 `5.5.0`） |
| dune | 3.24.x |
| ocaml-lsp-server | 1.27.x |
| utop | 2.17.x |
| ocamlformat | 0.29.x |
| menhir | 20260209 |

要装的库：`menhir sedlex ppx_deriving ppx_expect alcotest odoc ocamlformat fmt`。
`menhir` / `ocamllex` 是给后面写编译器用的，现在用不上但先装好。

**核对办法：`bash ./scripts/ocaml.sh check`**，它会把上面这七项逐条列出来，
两台机器上都是这一条命令。（2026-08-03 之前 `check` 只输出其中三项，
核对另外四项得手敲平台相关的命令——已经补齐了，不要再绕过脚本查版本。）

> 两台机器的版本**如果不一致**，以先记录在这里的为准，另一台去对齐。
> 已知不一致会导致 `dune-project` 的 `(lang dune 3.20)` 或 ocamlformat 行为出现差异。

## 两个已经踩过并修好的坑（两台都会遇到）

1. **apt 装 opam 会捎带一个系统 OCaml 到 `/usr/bin/ocaml`。**
   必须保证 opam switch 在 PATH 里优先，否则会静默用错编译器编译。
   验证：`command -v ocaml` 要指向 `~/.opam/5.5.0/bin/ocaml`，不是 `/usr/bin/ocaml`。

2. **`opam init` 只改 `~/.bashrc`，而 Ubuntu 的 `.bashrc` 对非交互 shell 会提前 return。**
   VS Code 和脚本调用都是非交互方式，结果是 `dune`、`ocamllsp` 全都找不到。
   修法：在 `~/.profile` 末尾补

   ```bash
   if [ -r "$HOME/.opam/opam-init/init.sh" ]; then
     . "$HOME/.opam/opam-init/init.sh" > /dev/null 2>&1 || true
   fi
   ```

   → 以后再出现「终端里能编译但 VS Code 报找不到 dune」，先查这里。

## 文件放哪（原则，两台通用）

实测数据来自 win10-laptop（WSL2，项目放在 Windows 盘 vs 放在 Linux 盘）：

| 场景 | Linux 原生盘 | Windows 盘（`/mnt/d`） |
|---|---|---|
| 单文件练习 冷构建 | 0.46 s | 6.92 s |
| 单文件练习 改一行重建 | 0.05 s | **0.26 s** |
| 重型项目（menhir+ppx）冷构建 | 1.28 s | 57.68 s |
| 建 2000 个小文件 | 0.51 s | 12.12 s |

结论（**只对 win10-laptop 有意义**，ubuntu24-pc 上不存在跨文件系统的问题）：

- **练习代码放 Windows 盘没问题** —— 内循环 0.26 秒感觉不到，换来文件集中管理。
- **重型项目要放进 Linux 盘** —— 差距会拉到几十倍。

顺带一提（两台通用）：`dune build --build-dir=<外部绝对路径>` 这条路走不通，
dune 会直接报 `Cannot create external build directory`，别再试了。

## 编辑器：OCaml 文件里关掉 AI 补全（2026-08-08，两台通用）

**起因**：练习题的注释里写着功能描述，**Codeium 直接据此补全出了正确实现**，
答案送到眼前，练习就白做了。

**做法**：`ocaml-learning/.vscode/settings.json`

```jsonc
"codeium.enableConfig": {
  "*": true,
  "ocaml": false,
  "ocaml.interface": false
}
```

- **只关 OCaml**（`.ml` / `.mli`），其他语言一律不受影响
- **没有关 `ocamllabs.ocaml-platform`（OCaml LSP）自带的补全** —— 那个基于类型和
  已有标识符，只提示「这里能填什么类型的东西」，不会替你把算法写出来，**对学习有益，留着**
- 以后写 `.mll` / `.mly` 想一起关，加 `ocaml.ocamllex` / `ocaml.menhir`
  （语言 ID 来自 ocaml-platform 扩展）

**⚠️ 这个文件是 `.gitignore` 的一个特例。** 仓库里 `.vscode/` 整体不进版本库，
但这条是教学设定、两台都要，所以单独放行了。`.gitignore` 里的写法：

```gitignore
**/.vscode/*
!**/.vscode/settings.json
```

**两个坑都实测过，别改回去：**

1. 目录被整体 ignore 时 git **不会下探**，负向规则会失效 → 必须写成 `.../*` 再放行
2. **含内部斜杠的模式会被锚定到仓库根** —— 写 `.vscode/*` 只能匹配根目录那个，
   匹配任意层级必须写 `**/.vscode/*`

**生效验证**：打开任意 `.ml` 文件敲几个字符，不应再出现灰色的整段建议。
没生效就 `Ctrl+Shift+P` → `Developer: Reload Window`。

## 仓库同步

- 仓库：`08822407d/MyCC`，本项目是其中的 `ocaml-learning/` 子目录。
- **两台机器交替使用，绝不同时用**，所以正常不会有冲突。
- `notes/` 是跨机器传递状态的唯一载体，改完要提交。
- `_build/` 已在 `.gitignore` 里，不要提交构建产物。
- **git 操作一律等用户开口**（用户明确要求的：2026-08-03）。Claude 不主动 commit/push/pull。
