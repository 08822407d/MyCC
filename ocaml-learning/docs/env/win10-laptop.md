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

## ✅ WSL Remote 模式的两个连带问题（2026-08-18 排查，**2026-08-20 修法已验证**）

> **2026-08-20 更新：网络链路已打通并实测确认。** 下面保留原始排查过程，
> **修正与验证结果见本节末尾的「2026-08-20 收尾」。**

### 🔴 2026-08-18 的一处误判（重要，别再犯）

**当时的结论「Claude Code 不需要代理，Anthropic 域名从 WSL 直连全通」是错的。**

错因：**只测了 `api.anthropic.com` 和 `claude.ai`，漏了 OAuth 真正用的第三个域名。**

```
api.anthropic.com     403  ✅   DNS → 160.79.104.10（真实 IP）
claude.ai             302  ✅
platform.claude.com   000  ❌   DNS → 31.13.95.38（Meta 段）+ 2001::（Teredo 段）← 污染
claude.com            000  ❌
```

`platform.claude.com` 是 `MANUAL_REDIRECT_URL` 和 `TOKEN_URL` 的宿主，
**DNS 污染 + SNI 阻断双重挡着**（强行 pin 到真实 IP 后 TLS Client Hello 仍被 RST）。
→ **两条线都绕不开代理。**

> 🚩 **教训：测「某家服务通不通」时，要测它【实际用到的每一个域名】，
> 不能拿主域名的可达性代表全部。** OAuth / 计费 / 遥测常常在不同域名上。

## ⚠️（存档）2026-08-18 的原始排查

> 起因：为了让 `ocamllsp` 跑起来，用 `WSL: Reopen Folder in WSL` 重开之后
> **Claude Code 和 ChatGPT/Codex 两个扩展都不见了**，装进 WSL 之后又登录失败。
> **下面的排查结论都是实测的；但修法当天没来得及验证，明天继续。**

### 一、扩展分两侧，Remote 模式下要各装各的

| 类别 | 装在哪 | 例子 |
|---|---|---|
| **UI 扩展** | Windows 侧 `~/.vscode/extensions` | 主题、键位、Vim |
| **Workspace 扩展** | **WSL 侧 `~/.vscode-server/extensions`** | 语言服务器、**Claude Code**、**ChatGPT/Codex** |

**不是丢了，是从来没装进 WSL 那一侧。** 装法：扩展面板里找到它 → 蓝色按钮
`Install in WSL: Ubuntu`；或在**连着 WSL 的内置终端**里 `code --install-extension <id>`。

### 二、代理：Win10 上 WSL **拿不到** Windows 的 `127.0.0.1` 代理

**实测事实（2026-08-18，本机）：**

```
Windows 代理     ProxyEnable=1, ProxyServer=127.0.0.1:7890
监听 7890 的进程  verge-mihomo，监听地址【只有 127.0.0.1】← 关键
防火墙           Domain/Private/Public 三个 Enabled 全是 False ← 不背这个锅
WSL 网络模式     默认 NAT（没有 ~/.wslconfig）
Windows 版本     Win10 19045 → 【用不了 networkingMode=mirrored】（那要 Win11）
Windows 主机在 WSL 里的地址   172.18.176.1（= 默认网关 = resolv.conf 的 nameserver）
从 WSL 连 172.18.176.1:7890   ❌ 拒绝
```

> **NAT 模式下 WSL 和 Windows 是两台机器，`127.0.0.1` 各指各的。**
> 把 Windows 的代理环境变量抄进 WSL 完全没用。

**直连可达性（从 WSL，不走代理）：**

```
api.github.com          ✅ 200      claude.ai              ✅ 302
console.anthropic.com   ✅ 301      api.anthropic.com      ✅ 403（能到，只是没凭证）
chatgpt.com             ❌ 不通      api.openai.com        ❌ 不通
```

→ **Anthropic 全通、OpenAI 不通。所以两个扩展登录失败的原因不一样。**

### 三、两条修法（**都还没验证**）

**Claude Code —— 不需要代理。** 网络层是通的，登录失败大概率是 **OAuth 回调**：
浏览器在 Windows 上打开，回调地址 `http://localhost:PORT` 指的是 **Windows 的 localhost**，
而扩展在 **WSL** 的 localhost 上监听——两个不是同一个。
→ **绕开办法**：WSL 终端里跑 `claude`，用 `/login` 走「开链接 → 手动贴授权码」那条路，
不依赖回调端口。登录态存在 WSL 的 `~/.claude/`，VS Code 扩展会复用。

**Codex/ChatGPT —— 需要代理，两步：**

1. **Clash Verge 开「允许局域网连接」(Allow LAN)** → 监听地址从 `127.0.0.1:7890`
   变成 `0.0.0.0:7890`。**防火墙全关着，不用另加规则。**
2. WSL 的 `~/.bashrc` 里动态指过去（⚠️ **NAT 模式网关 IP 会变，别写死**）：

   ```bash
   export HOST_IP=$(ip route show default | awk '{print $3}')
   export http_proxy="http://$HOST_IP:7890"
   export https_proxy="$http_proxy"
   export all_proxy="socks5://$HOST_IP:7890"
   export no_proxy="localhost,127.0.0.1,::1"
   ```

   ⚠️ **VS Code 的远程扩展宿主不一定读 `.bashrc`**。还不行就在 **Remote [WSL] 作用域**
   加 `"http.proxy": "http://172.18.176.1:7890"` —— **那条只能写死 IP**，
   WSL 重启后网关变了要跟着改。这是 Win10 的结构性限制。

### 五、✅ 2026-08-20 收尾：修法与验证结果

**根因是三层叠加，缺一不可：**

| # | 问题 | 证据 |
|---|---|---|
| 1 | Clash Verge 只绑回环 | `config.yaml` L7 `allow-lan: false`；监听 `127.0.0.1:7890` |
| 2 | VS Code 把 `http.proxy` **原样下发**到 WSL | 用户设置 `"http.proxy": "http://127.0.0.1:7890"` 是 **APPLICATION 作用域**；<br>下发后那个 `127.0.0.1` 指 WSL 自己 → 日志 `ECONNREFUSED 127.0.0.1:7890` |
| 3 | Claude Code 扩展**没有代理配置项** | 15 个配置项里零个代理相关，只能靠 `claudeCode.environmentVariables` 注入 |

**第 0 步（用户 GUI）**：Clash Verge → 设置 → Clash 设置 → **开「允许局域网连接」**。
改完 `config.yaml` L7 变 `allow-lan: true`，监听地址变成 `::`（双栈）。
⛔ 别改 `clash-verge.yaml` / `profiles/*.yaml` —— 每次启动由 `config.yaml` 合成覆盖。

**第 1 步（可代跑）**：新建 `/home/cheyh/.vscode-server/data/Machine/settings.json`：

```jsonc
{
  "http.useLocalProxyConfiguration": false,   // 不加这条，下面几条被 Windows 侧压着
  "http.proxy": "http://172.18.176.1:7890",
  "http.proxyStrictSSL": true,                // ⚠️ 安全项，见下
  "claudeCode.environmentVariables": [
    { "name": "HTTP_PROXY",  "value": "http://172.18.176.1:7890" },
    { "name": "HTTPS_PROXY", "value": "http://172.18.176.1:7890" },
    { "name": "NO_PROXY",    "value": "localhost,127.0.0.1,::1" }
  ]
}
```

⚠️ **`http.proxyStrictSSL` 是安全项**：Windows 侧是 `false`，下发到 WSL 会让扩展给子进程注入
`NODE_TLS_REJECT_UNAUTHORIZED=0`（**等于在 WSL 里关掉 TLS 校验**）。远程侧设回 `true` 挡住。

⚠️ `172.18.176.1` 是 NAT 网段的网关，**WSL 重启可能变**。变了改这个文件，
或先跑 `wsl -d Ubuntu -- bash -lc 'ip -4 route show default'` 确认。

**第 2 步（用户）**：`Developer: Reload Window` → 登录。
⚠️ **登录不走 localhost 回调**（扩展里 `asExternalUri` 出现 0 次，
`registerUriHandler` 只处理 `/install-plugin` 和 `/open`）。
redirect 是远程页面 `https://platform.claude.com/oauth/code/callback`，
**授权后页面给一段 code，手动贴回**——这是默认行为，不用找端口转发开关。

**✅ 第 0 步之后的实测（2026-08-20）：**

```
端口连通性 172.18.176.1:7890        ✅
platform.claude.com   直连 000 → 走代理 200
claude.com            直连 000 → 走代理 200
chatgpt.com           直连 000 → 走代理 403（Cloudflare 挡 curl，属正常）
api.openai.com        直连 000 → 走代理 421
POST /v1/oauth/token  走代理 400（空 body 的正常响应，不再是 000）
```

**⛔ 安全提醒**：`allow-lan` 打开后 7890 **同时暴露在物理网卡上，且代理无密码**。
要收紧就在 `config.yaml` 把 `bind-address` 设成 `172.18.176.1`（只对 WSL 那张网卡开）。

**备选（不动代理）**：`api.anthropic.com` 从 WSL 直连可达，注入 `ANTHROPIC_API_KEY` 即可，
全程不碰 `platform.claude.com`。**代价：走 API 计费，不吃订阅额度。**

### 四、⚠️ 排查时踩的老坑（第二次了）

**变量穿过 `wsl -d Ubuntu -- bash -lc '…'` 会被吃掉**（`$GW`、`$NS` 全成空串）。
第一次是 2026-08-07 查 gcc/nasm 时踩的，**这次又踩了一遍**。
→ **要在 WSL 里跑带变量的脚本，就写成 `.sh` 文件再 `bash 路径` 执行**，别塞进 `-lc`。

## VS Code

> **⚠️ 2026-08-18 实测确认（这台机器上反复踩）**：只要是用 **Windows 模式**打开文件夹，
> **悬停看类型、跳转、库函数文档说明全都不工作** —— 因为扩展跑在 Windows 侧，
> 而 `ocamllsp` 只存在于 WSL 里（`where ocamllsp` 在 Windows 上返回空）。
> **两侧的扩展都装好了**（Windows `~/.vscode/extensions`、
> WSL `~/.vscode-server/extensions` 都有 `ocamllabs.ocaml-platform-2.3.0`），
> **问题只在于用哪一侧打开**。
> → `F1` → `WSL: Reopen Folder in WSL`，路径变成 `/mnt/d/MyCC/ocaml-learning`，
> LSP 立刻接上，顺带内置终端也直接是 Ubuntu。
>
> **「库函数功能说明」不需要装任何新插件** —— `ocamllsp` 的悬停提示本来就带
> `.mli` 里的文档注释。想要离线全量文档站：WSL 里 `opam install odig` 然后 `odig doc`。


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
