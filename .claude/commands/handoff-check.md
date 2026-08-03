---
description: 交接自检 — 转发到 ocaml-learning 的自检任务书（工作目录开在仓库根时用这个）
---

# 交接自检（仓库根目录入口）

用户是在仓库根目录 `MyCC/` 打开的，而这个自检属于 `ocaml-learning/` 子项目。

**这个文件本身不含任何检查步骤，只是转发。真正的任务书是：**

`ocaml-learning/.claude/commands/handoff-check.md`

## 你要做的

1. **先读那个文件**（这是唯一允许在「阶段 0 闭卷」之前读的文件），然后**严格照它执行**。
2. 那份任务书里所有写成 `<脚本>` 的地方，在这里都展开成
   `./ocaml-learning/scripts/ocaml.sh`；所有相对路径都加 `ocaml-learning/` 前缀
   （比如报告写到 `ocaml-learning/notes/handoff-report.md`）。
3. 在报告的「工作目录」一栏注明：**用户是在仓库根目录打开的，不是推荐的
   `ocaml-learning/`**。这不算失败，但要记一笔 —— 推荐直接打开子目录，路径更短。

不要在这里重新发明检查步骤，一切以那份任务书为准。
