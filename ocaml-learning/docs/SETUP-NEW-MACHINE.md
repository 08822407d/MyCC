# 在一台新机器上装好环境

仓库里**只有代码和笔记，没有 OCaml 工具链**。换机器要重装一遍。

## 先看你在哪种机器上

| 情况 | 第 1～5 步 | 第 6 步（VS Code） |
|---|---|---|
| **Windows + WSL2**（`win10-laptop`） | 在 WSL 的 Ubuntu 里执行 | 走 A 分支 |
| **原生 Linux**（`ubuntu24-pc`） | 直接在系统里执行 | 走 B 分支 |

**第 1～5 步两种情况的命令完全一样**，区别只在「在哪个 shell 里敲」。
只有第 6 步的 VS Code 装法不同。

下面的流程是当初在 `win10-laptop` 上走通的，踩过的坑都写进去了。

---

## 1. 装编译依赖

```bash
sudo apt-get update
sudo apt-get install -y build-essential m4 unzip curl git pkg-config bubblewrap rsync ca-certificates
```

## 2. 装 opam

优先用 apt 的（省事，而且不依赖 GitHub 下载）：

```bash
sudo apt-get install -y opam
opam --version      # 2.5 以上即可
```

> 如果 apt 源里版本太老，才考虑 <https://github.com/ocaml/opam/releases> 下二进制。
> 注意某些网络环境下 `objects.githubusercontent.com` 连不上，
> 而 `codeload.github.com` 和 `opam.ocaml.org` 是通的。

## 3. 初始化 opam 并建 switch

```bash
opam init --bare --auto-setup --yes --disable-sandboxing
opam switch create 5.5.0 ocaml-base-compiler.5.5.0
eval $(opam env --switch=5.5.0)
ocamlc -version     # 应输出 5.5.0
```

编译器要从源码构建，几分钟。

## 4. ⚠️ 修 PATH（这一步很容易漏，漏了 VS Code 会失灵）

`opam init` 只往 `~/.bashrc` 里写环境钩子，但 **Ubuntu 的 `.bashrc` 对非交互 shell 会提前
`return`**，而 VS Code 和 `wsl -- 命令` 恰恰是非交互方式启动的。
结果就是「终端里能编译，VS Code 里报找不到 dune」。

在 `~/.profile` 末尾补上：

```bash
if [ -r "$HOME/.opam/opam-init/init.sh" ]; then
  . "$HOME/.opam/opam-init/init.sh" > /dev/null 2>&1 || true
fi
```

验证（**必须用 `bash -lc` 这种登录 shell 来验**）：

```bash
bash -lc 'command -v dune ocamllsp; ocamlc -version'
```

还要确认 `ocaml` 指向的是 `~/.opam/5.5.0/bin/ocaml`，
**不是** `/usr/bin/ocaml` —— apt 装 opam 时会捎带一个系统 OCaml，别让它抢了 PATH。

## 5. 装工具链和库

```bash
opam install -y dune merlin ocaml-lsp-server ocamlformat utop odoc \
                menhir sedlex ppx_deriving ppx_expect alcotest fmt
```

`menhir` / `ocamllex` 是后面写编译器要用的。

## 6. VS Code

### A 分支 — Windows + WSL2

- **Windows 侧**装 `ms-vscode-remote.remote-wsl`
- **WSL 侧**装 `ocamllabs.ocaml-platform` ← 只装 Windows 侧不管用

WSL 侧的装法：在 WSL 终端里执行

```bash
code --install-extension ocamllabs.ocaml-platform
```

（首次会先下载 vscode-server，等一会儿。）

### B 分支 — 原生 Linux

直接装就行，不涉及 remote：

```bash
code --install-extension ocamllabs.ocaml-platform
```

## 7. 拉仓库并验证

```bash
git clone https://github.com/08822407d/MyCC.git
cd MyCC/ocaml-learning
bash ./scripts/ocaml.sh check          # 平台那行要对；工具路径应全部指向 ~/.opam/5.5.0/bin
bash ./scripts/ocaml.sh run ex00_smoke # 应输出 hello
```

两条都通过，就可以接着用 `notes/PROGRESS.md` 继续学了。

> 注意 `check` 第一行会打印它认为的当前平台。如果在原生 Linux 上却显示成别的，
> 说明脚本的平台判断出问题了，先修那个 —— 后面所有命令都依赖它。

## 8. 把这台机器登记进文档

装完之后，去 `docs/env/` 下对应的单机文档里把实际情况填上
（仓库绝对路径、opam switch 名、版本），并对照 `docs/env/COMMON.md` 的版本口径核对。
**两台机器版本对不上会出问题**，早发现早对齐。

---

## 关于仓库放哪

**只有 Windows + WSL2 才需要考虑这件事**（原生 Linux 不存在跨文件系统的问题）。

代码可以放 Windows 盘（`/mnt/...`），练习级项目改一行重建约 0.26 秒，感觉不到。
但**重型项目（引入 menhir + ppx 的完整编译器）要放进 WSL 的 `~/`**，
放在 Windows 盘上全量冷构建会从 1 秒掉到 50 秒以上。
详见 [`env/COMMON.md`](env/COMMON.md) 的实测数据。
