# 009. `c-lexer/` 不独立存在：文档并入 `spec/lexer/`，代码动工时直接建在 `compiler/`

> **状态**：✅ 已定
> **日期**：2026-08-26（`ubuntu24-pc`）
> **依据来源**：我的建议，**用户确认**（原话「都按照你推荐的方案走」，与 Q13/Q14 同批）

## 背景

= REQUIREMENTS §2 的待定 = 开放问题 L8 / Q12。`MyCC/c-lexer/` 是 2026-08-25 按用户
「在专门为这个目的创建的文件夹里」的要求建的，但 `MyCC/compiler/` 同层已存在、
也是为编译器代码准备的，职责重叠。

## 结论

- **`c-lexer/` 目录取消。** 两份文档（`REQUIREMENTS.md` / `DESIGN.md`）
  迁入 **`compiler-roadmap/spec/lexer/`**（`spec/` 本来就是「定稿」的家，符合仓库分工）
- **代码动工时直接建在 `compiler/`**：`dune-project` + `bin/` + `lib/lexer/` + `test/`，
  **整个编译器一个 dune 工程**
- 原 `c-lexer/` 暂留一个指针 README（它是设计任务的会话工作目录，进程占着；
  **删除留给用户**）

## 理由

1. **dune 的工程根由 `dune-project` 文件决定**：两个目录各放一个 = 两个互不相干的
   dune 工程，将来 parser 引用 lexer 要走 opam 安装或 vendoring；
   同一工程下只是 `(libraries mycc_lexer)` 一行
2. `compiler/` 现在是空壳，**这是最便宜的合并时机**
3. 仓库分工（`compiler-roadmap/` 放文档、`compiler/` 放代码）本来就有，
   `c-lexer/` 和两者都重叠

## 代价 / 放弃了什么

- 推翻了用户 2026-08-25 「专门创建文件夹」的字面要求（**用户本人确认的推翻**）
- 文档路径变动，既有交叉引用需同步修（005–008 / CLAUDE.md / compiler/README /
  DESIGN-LOG / OPEN-QUESTIONS，2026-08-26 已全部改完）

## 备选项（为什么没选）

| 选项 | 为什么没选 |
|---|---|
| `c-lexer/` 独立放代码 + 自己的 `dune-project` | 将来接 parser 要还 dune 的债（跨工程引用） |
| 文档留在 `c-lexer/` 不动 | 与「文档归 roadmap、代码归 compiler」的既定分工冲突，第三个存放地 |

## 影响到的其他东西

- REQUIREMENTS §2 的待定关闭
- `compiler/README.md`「动工时要建的东西」有了具体布局（已加指针）
- `compiler-roadmap/CLAUDE.md` 目录约定里 `spec/`「现在还空着」不再成立（已改）

## 复议条件

无——纯布局问题，真到动工发现不合适，改起来也便宜。
