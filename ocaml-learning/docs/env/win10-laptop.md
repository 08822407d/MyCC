# win10-laptop — Windows 10 笔记本（办公室）

会话环境信息里 `Platform: win32` 就是这台。通用部分见 [`COMMON.md`](COMMON.md)。

配置时间：2026-07-28 / 2026-07-29。

## 结构

```
Windows 10                          WSL2 Ubuntu 26.04
──────────                          ─────────────────
VS Code 界面                   ⟷    vscode-server
D:\MyCC\ocaml-learning         ⟷    /mnt/d/MyCC/ocaml-learning  （同一份文件）
                                    OCaml 工具链（opam switch 5.5.0）
                                    参考项目 ~/ocaml/toylang
```

**Windows 上没有 OCaml，全部装在 WSL 里。** 任何编译动作都必须落到 WSL 内执行。

## ⚠️ 只在本机成立

- **WSL 发行版名叫 `Ubuntu`**，版本 26.04 LTS。
- **WSL 虚拟磁盘在 `D:\WSL\Ubuntu\ext4.vhdx`**，不在默认的 `%LOCALAPPDATA%\wsl`。
  当初 C 盘只剩 29 GB，用 `wsl --manage Ubuntu --move D:\WSL\Ubuntu` 搬走了，
  注册表 BasePath 已自动更新。
- **项目路径 `D:\MyCC\ocaml-learning`**，WSL 里看到的是 `/mnt/d/MyCC/ocaml-learning`
  —— 也就是说项目在 Windows 盘上，是跨文件系统访问（性能代价见 COMMON.md，可接受）。
- 参考项目 `~/ocaml/toylang` 在 **WSL 内**（ocamllex → menhir → AST → 求值器骨架），
  留着以后做编译器练习时当范本。

## 命令

日常用统一入口就行，脚本会自己转进 WSL：

```bash
bash ./scripts/ocaml.sh run ex01_int_float
```

只有**绕过脚本**时才需要自己加前缀，而且**必须套一层 `bash -lc`**：

```bash
wsl -d Ubuntu -- bash -lc '<任意 Linux 命令>'
```

⚠️ **不要写成 `wsl -d Ubuntu -- <命令>`**（2026-08-03 实测踩到）：

```bash
wsl -d Ubuntu -- command -v utop              # → 退出码 1，找不到
wsl -d Ubuntu -- bash -lc 'command -v utop'   # → /home/cheyh/.opam/5.5.0/bin/utop
```

`wsl -- xxx` 是**直接执行程序，不经过任何 shell**，于是 opam 的 PATH 压根没被加载。
根因就是 [`COMMON.md`](COMMON.md) 记的第 2 个坑（opam 的初始化写在 `~/.profile` / `~/.bashrc` 里）。
交互式进去（`wsl -d Ubuntu` 不带参数）不受影响，那会读 `.bashrc`。

## 从 Windows 侧开 utop（交互式顶层）

`utop` = **U**niversal **top**level，OCaml 的加强版 REPL（自带行编辑、历史、Tab 补全、
高亮）。OCaml 也有个裸的顶层，命令就叫 `ocaml`，能用但难用。
**它是 opam 包，不是 macOS 专属的东西**；本机装在 WSL 的 switch 里（2.17.0）。

Claude 起不了它（需要交互终端），**下面几条是给人用的**：

| 方式 | 怎么做 |
|---|---|
| **Windows Terminal**（最省事） | 标签页旁下拉箭头 → `Ubuntu` → `cd /mnt/d/MyCC/ocaml-learning && utop` |
| **VS Code**（附加价值最大） | `F1` → `WSL: Reopen Folder in WSL`，终端默认就是 Ubuntu，**而且 ocamllsp 才真正接得上** |
| PowerShell | `wsl -d Ubuntu` 进交互 shell 再敲 `utop`；或 `wsl -d Ubuntu -- bash -lc utop` |
| 项目入口 | Git Bash 里 `bash ./scripts/ocaml.sh repl` |

> 只用 Windows 侧打开文件夹时，LSP 接的是 Windows 上并不存在的 ocamllsp，
> 所以跳转/悬停看类型都不工作 —— 这是选 VS Code 那条路的主要理由。

**坑**：在顶层里每段代码要 `;;` 结尾才会执行，但 **`;;` 是顶层的规矩，不是 OCaml 语言的一部分**，
写 `main.ml` 时不需要。跟着公开课敲完 REPL 回头写文件时到处撒 `;;`，就是在这儿混的。
退出用 `#quit;;` 或 Ctrl-D。

## VS Code

- **Windows 侧**装 `ms-vscode-remote.remote-wsl`
- **WSL 侧**装 `ocamllabs.ocaml-platform`（2.3.0）← 只装 Windows 侧不管用

打开方式：WSL 终端里 `code .`，或 `Ctrl+Shift+P` → `WSL: Connect to WSL`。

## 截屏：Claude 可以自己截图看渲染效果（2026-08-06 实测可用）

调 UI / 排版类问题时有用 —— **Claude 能自己截屏并读图**，不用让用户描述看到了什么。
**Windows 自带 .NET 就够，不需要安装任何工具。**

```powershell
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$s = [System.Windows.Forms.Screen]::AllScreens | Where-Object { -not $_.Primary } | Select-Object -First 1
$b = $s.Bounds
$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
$bmp.Save("<路径>.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
```

存到 scratchpad，然后用 `Read` 工具读那个 png 就能看见。

### ⚠️ 本机特有的三个坑

1. **两块 1080×1920 竖屏并排**（`DISPLAY1` @ (0,0) 主屏，`DISPLAY2` @ (1080,0)）。
   **对话窗口在副屏**，`PrimaryScreen` 截到的是另一块 —— 第一次就踩了这个，白截一张。
   所以上面的代码筛的是 `-not $_.Primary`。
2. **截屏会拍到用户的其它窗口**（第一次拍到了浏览器里的别的会话）。
   **截之前先说一声，用完立刻删**，不要留在磁盘上。
3. 同一轮里**先输出待测的 markdown、再截屏**是可行的 —— 已输出的文本此时已经渲染出来了，
   不需要等用户回话。这样一轮就能自测排版效果。

## 汇编 / 链接工具链（2026-08-06 实测）—— ⚠️ **和台式机不一样**

伯克利那门课的玩具编译器要调 `nasm` + `gcc` 把汇编跑起来
（配方见 [`../../notes/concepts/07-toy-compiler-pipeline.md`](../../notes/concepts/07-toy-compiler-pipeline.md)）。
**这台机器的 WSL 里少一个：**

| 工具 | 本机（win10-laptop / WSL） | 对照 ubuntu24-pc |
|---|---|---|
| **nasm** | ❌ **没装** | ✅ `/usr/bin/nasm` |
| gcc | ✅ `/usr/bin/gcc`（15.2.0） | ✅ |
| ld | ✅ `/usr/bin/ld` | ✅ |
| 架构 | `x86_64` | `x86_64` |

**所以那条链路在这台机器上现在跑不通**，要跑得先补：

```bash
wsl -d Ubuntu -- bash -lc 'sudo apt install nasm'
```

（`elf64` 那条改动两台机器一样——都是 Linux，不是讲师的 macOS `macho64`。）

> ⚠️ **顺带记一个查工具时踩过的坑**（2026-08-05）：用
> `for t in gcc nasm; do ... $t ...; done` 这种循环写法通过
> `wsl -d Ubuntu -- bash -lc '...'` 传进去时，**变量会被吃掉**，
> 结果每一项都报「没装」——当时因此**误报 gcc 没装**。
> **查工具就直接写死命令名**，别在传给 WSL 的字符串里用循环变量。

## Windows 侧工具版本（2026-08-03 核对）

跟 OCaml 无关，但属于本机状态，换机器时不要照抄：

- **PowerShell 7.6.4**，单一 MSI 安装在 `C:\Program Files\PowerShell\7`
- **Windows Terminal** 稳定版 1.24.11911.0 + 预览版 1.25.1912.0（Store 自更新）
- `winget` 在 `%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe`，1.29.280

⚠️ **升级 PowerShell 别用 `winget install Microsoft.PowerShell`**（2026-08-03 踩到）：
winget 给的是 **MSIX 包**，装完不进 `Program Files`，于是和已有的 MSI 安装**并存两份**，
而 `pwsh` 仍解析到旧的那份（`C:\Program Files\PowerShell\7` 在 PATH 里排得更靠前）。
要原地升级就从 GitHub Releases 取官方 MSI：

```powershell
# PowerShell-<版本>-win-x64.msi，装的时候带 ADD_PATH=1
msiexec /i PowerShell-7.6.4-win-x64.msi /qn ADD_PATH=1
```

⚠️ **「添加删除程序」里那两条 PowerShell 名字有误导性**：`PowerShell 7-x64` 是**当前有效**的
MSI 安装，`PowerShell 7.6.3.0-x64` 那种带完整版本号的才是残留僵尸条目。别删错了 ——
删错会把 `Program Files` 那份整个干掉，`pwsh` 直接从 PATH 上消失。

## vhdx 空间回收（本机特有的维护动作）

vhdx 只会涨不会自己缩。要回收：

```powershell
wsl -d Ubuntu -- sudo fstrim -av
wsl --shutdown
Optimize-VHD -Path D:\WSL\Ubuntu\ext4.vhdx -Mode Full   # 需要 Hyper-V 模块
```

没有 Hyper-V 就用 diskpart：`select vdisk file="..."` → `attach vdisk readonly`
→ `compact vdisk` → `detach vdisk`。

**不要用 `wsl --manage ... --set-sparse true`**：WSL 2.7 已经禁用它，
说存在潜在数据损坏风险，要强开得加 `--allow-unsafe`。不值得。
