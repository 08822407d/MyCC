# 11. 记录（record）

> 2026-08-08。起因是用户从伯克利公开课带回一张截图：
> `type project = { itm: item; fab: fabric } ;;`，问「这是什么」。
>
> ⚠️ **他其实见过一次**：知识点 8 里 `ref` 的真身就是记录
> （`type 'a ref = { mutable contents : 'a }`），当时没点名。

## 11.1 就是 OCaml 版的 struct

> **记录（record）** — 有**命名字段**的复合类型。

```c
struct project { item itm; fabric fab; };        /* C */
```
```ocaml
type project = { itm : item; fab : fabric }      (* OCaml *)
```

- 取字段也用点号：`p.itm`
- 字段间的 `;` 是**分隔符**不是结束符（尾随一个也合法）
- 末尾 `;;` 是顶层的规矩，`.ml` 文件里不需要

## 11.2 和变体（ADT）是一对

| | 意思 | C 里对应 |
|---|---|---|
| 变体 `Circle \| Square` | **或**——是这个**或**那个 | tagged union |
| 记录 `{ itm; fab }` | **且**——既有这个**又**有那个 | struct |

课上那行正是把两者套在一起：`item` 和 `fabric` 各自是变体，`project` 把它们组合起来。
**这套组合拳就是 OCaml 描述数据的标准手法，以后写 AST 全靠它。**

## 11.3 用法（全部实测）

```ocaml
let p = { itm = Shirt; fab = Cotton }   (* val p : project = {itm = Shirt; fab = Cotton} *)
p.itm                                   (* val what : item = Shirt *)
```

⚠️ **定义用冒号 `itm : item`，造值用等号 `itm = Shirt`** —— 两处形状像，别写混。

**记录默认不可变**，"改一个字段"实际是**在运行时造一个新记录**：

```ocaml
let q = { p with fab = Wool }
(* val q : project = {itm = Shirt; fab = Wool}  —— p 原封不动 *)
```

## 11.4 C# 类比（放开用，用户明确想加深 C#）

**`{ p with … }` 和 C# 9 `record` 的 `with` 表达式是同一个东西，连关键字都一样。**
而且 OCaml 记录默认不可变、用 `=` 比较是**结构相等**
（实测 `p = { itm = Shirt; fab = Cotton }` → `true`）——正是 C# 9 `record` 给你的那一套。
**名字撞上不是巧合，C# 那个特性就是从 ML 借的。**

## 11.5 可变字段

想要能改的字段，字段前加 `mutable`（`ref` 定义里那个 `mutable` 就是它）：

```ocaml
type p = { mutable x : int }
let p = { x = 1 } in p.x <- 9; p.x      (* → 9 *)
```

⚠️ **赋值用 `<-`**，不是 `:=`（`:=` 是 `ref` 专用的，而 `ref` 本身就是个 mutable 记录）。
**`<-` 属于「阶段 D 小语法集中扫」，只提了没展开。**

## 11.6 还没讲的

- 记录模式（在 `match` / `let` 里拆记录：`{ itm; _ }`）
- 字段名冲突时的消歧（两个记录类型有同名字段）
- 记录的类型推断怎么靠字段名定位类型
