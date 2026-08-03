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

1. **看会话开头的环境信息里的 `Platform:` 字段**
   - `win32` → `win10-laptop`
   - `linux` → `ubuntu24-pc`
   这是免费的，不用跑命令，绝大多数情况用这个就够了。

2. **不确定就跑一条命令问**：

   ```bash
   bash ./scripts/ocaml.sh platform
   ```

   输出 `wsl ...` 是笔记本，`linux ...` 是台式机。

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
