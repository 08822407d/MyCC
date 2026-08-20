# 环境说明（索引）

用户有**两台开发机，交替使用，不会同时用**：

| 代号 | 机器 | 在哪 | 文档 |
|---|---|---|---|
| `win10-laptop` | Windows 10 笔记本，OCaml 装在 WSL2 Ubuntu 里 | 办公室 | [`env/win10-laptop.md`](env/win10-laptop.md) |
| `ubuntu24-pc` | Ubuntu 24.04 台式机，原生 Linux | 家里 | [`env/ubuntu24-pc.md`](env/ubuntu24-pc.md) |

**两台机器都成立的内容**（版本选择、踩过的坑、性能实测、文件放哪的原则）
统一放在 [`env/COMMON.md`](env/COMMON.md)，不要抄进单机文档里。

新机器从零装环境看 [`SETUP-NEW-MACHINE.md`](SETUP-NEW-MACHINE.md)。

---

## 怎么知道现在在哪台机器上

**这件事必须先确认，再执行任何跟平台有关的操作。** 三种办法，从便宜到贵：

> **2026-08-20 判据改了。** 原来第一条是「看会话的 `Platform:` 字段」，
> 但笔记本的 VS Code 切到 **WSL 远程模式**之后**也报 `Platform: linux`** ——
> `linux` 不再唯一对应台式机。**现在以命令为准。**

1. **跑一条命令（唯一可靠）**：

   ```bash
   bash ./scripts/ocaml.sh platform
   ```

   | 输出 | 机器 |
   |---|---|
   | `win-gitbash` | `win10-laptop`（Windows 的 Git Bash，脚本会自动转进 WSL） |
   | **`wsl`** | **`win10-laptop`**（VS Code 的 WSL 远程模式，或直接在 WSL 里） |
   | `linux` | `ubuntu24-pc`（原生 Linux） |

   它靠 `/proc/version` 里有没有 `microsoft` 区分 WSL 和原生 Linux，**不受编辑器模式影响**。

2. **会话的 `Platform:` 字段只有一半有效**：
   - `win32` → 确定是 `win10-laptop`
   - `linux` → **无法区分**，必须跑上面那条命令

   旁证（不如命令权威，但可佐证）：工作目录是 `/mnt/d/…` 或 `d:\MyCC\…` → 笔记本；
   `/home/cheyh/projs/…` → 台式机。`/mnt/c` 存在也说明是 WSL。

3. `bash ./scripts/ocaml.sh check` —— 顺带把工具链版本一起列出来。

## 好消息：构建命令两台机器是同一条

`scripts/ocaml.sh` 自己会判断平台。在 Windows 的 Git Bash 里被调用时，
它会 `exec` 进 WSL 再跑一遍，所以**不需要**手写 `wsl -d Ubuntu --` 前缀：

```bash
bash ./scripts/ocaml.sh run ex01_int_float     # 两台机器完全一样
```

也就是说，**日常最高频的那类平台差异已经被脚本吃掉了**。
需要留神平台的是别的东西：文件路径、磁盘管理、VS Code 扩展装在哪、以及任何绕过脚本的命令。
详见两个单机文档里的「⚠️ 只在本机成立」小节。
