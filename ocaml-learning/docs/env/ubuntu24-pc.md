# ubuntu24-pc — Ubuntu 24.04 台式机（家里）

会话环境信息里 `Platform: linux` 就是这台。通用部分见 [`COMMON.md`](COMMON.md)。

## 状态：环境已装，但**版本尚未核对**

用户自述「装了但不确定版本」（2026-08-03）。所以这份文档里带 ❓ 的字段都是**待确认**，
不是已知事实 —— 在核对之前，不要拿它当依据回答用户的问题。

## ⚠️ 只在本机成立

- **原生 Linux，没有 WSL。** 不存在 `wsl -d Ubuntu --` 这种前缀，
  也不存在 `/mnt/d` 跨文件系统的性能问题。看到任何带 `wsl` 的命令就是拿错平台了。
- 仓库路径：❓ 待确认（第一次在这台机器上开对话时填）
- opam switch 名 / 编译器版本：❓ 待确认，期望和 COMMON.md 一致（`5.5.0`）
- 参考项目 `toylang` 在这台机器上有没有：❓ 待确认

## 第一次在这台机器上开对话时，Claude 要做的事

按顺序执行，然后**把结果回填进本文件**，把 ❓ 换成事实：

1. 跑自检：

   ```bash
   bash ./scripts/ocaml.sh check
   ```

2. 对照 [`COMMON.md`](COMMON.md) 的版本口径逐项核对：
   - 平台那一行应显示 `linux`
   - `ocamlc -version` 应是 `5.5.0`
   - `dune --version` 应是 `3.24.x`
   - 工具路径应指向 `~/.opam/5.5.0/bin/`，**不是** `/usr/bin/ocaml`
     （COMMON.md 的坑 1）

3. 冒烟测试：

   ```bash
   bash ./scripts/ocaml.sh run ex00_smoke     # 应输出 hello
   ```

4. 记下仓库的绝对路径（`pwd`），填到上面。

5. 把核对结果写进本文件并告诉用户；如果版本对不上，一并说清差在哪、要不要对齐。
   （提交由用户决定，Claude 不主动 git。）

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
