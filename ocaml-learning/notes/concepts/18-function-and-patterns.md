# 18. 语法小件（一）：`function` 关键字 + 嵌套模式

> 2026-08-16 讲的，对应 [`../CURRICULUM.md`](../CURRICULUM.md) 的 **D1**。
>
> **用户 2026-08-16 主动选的**：「我想先把语言基础要素了解清楚」→ 从三选一里挑了
> 「语法小件集中扫」。**D1 还剩 `when` 守卫、`and` 相互递归、可变字段 `<-` 没讲。**

## 18.1 `function`：纯语法糖

> **`function` ≡ `fun x -> match x with`** —— 一次干两件事：收一个参数、立刻对它 `match`。

```ocaml
let f = function 0 -> "zero" | _ -> "other"          (* val f : int -> string *)
let f x = match x with 0 -> "zero" | _ -> "other"    (* val f : int -> string *)
```

**两行类型完全一样。** 省掉的正是那个**只用一次的参数名**。

### ⭐ 有效的切入：他早就见过了

```ocaml
(* ex04 自测代码里（我让他"别改"那一段） *)
let show_fab = function Linen -> "Linen" | Cotton -> "Cotton" | Wool -> "Wool"

(* ~/projs/ocaml-compiler-lab/lib/ast.ml —— 他的目标项目 *)
let rec show = function
  | Int n -> string_of_int n
  | ...
and show_binop = function Add -> "+" | ...
```

**指给他看「你已经见过它」比讲定义有效。**

### ⚠️ 只能顶掉最后一个参数

因为它就是 `fun x -> …`，只吃一个：

```ocaml
let g prefix = function 0 -> prefix ^ "zero" | n -> prefix ^ string_of_int n
(* val g : string -> int -> string —— prefix 还得正常写在前面 *)
```

要对多个参数一起 match，还是得 `match (a, b) with`（元组模式）。

## 18.2 嵌套模式：把模式当积木往里套

**没有新规则**——构造器的空位里可以再填一个**模式**，而不只是名字或 `_`。

起因是他从公开课带回的截图：

```ocaml
type s_exp = Sym of string | Num of int | Lst of s_exp list

| Lst (Sym "if" :: _) -> true
```

一个模式里套了**三层**：

```
Lst ( Sym "if"  ::  _ )
 ↑      ↑    ↑    ↑   ↑
构造器  构造器 常量  ::  通配符
```

读作：「是个 `Lst`，**而且**里面那张表非空，**而且**表头是 `Sym`，**而且**那个 `Sym` 装的字符串正好是 `"if"`」——**四个条件一次判完**。

## 18.3 ⭐⭐ 用户的困惑（很有价值，讲法可复用）

截图里的函数：

```ocaml
let rec has_if (e : s_exp) : bool =
  match e with
  | Sym _ -> false
  | Num _ -> false
  | Lst (Sym "if" :: _) -> true
  | Lst l -> List.exists has_if l          (* ← 他卡在这一行 *)
```

**他的疑问**：最后一条是递归，但**没有拆列表**，那递归内层怎么拿到剩余列表？不会死循环吗？

> **他的推理完全正确** —— 如果真把 `l` 传给 `has_if`，那确实是死循环。
> **但 `List.exists has_if l` 不是把 `l` 传给 `has_if`，是把 `l` 的每个元素分别传给它。**

```
List.exists : ('a -> bool) -> 'a list -> bool
l : s_exp list        has_if : s_exp -> bool
```

**实测的调用轨迹**（拿 `Lst [Sym "foo"; Num 1; Lst [Sym "bar"; Sym "a"]]`）：

```
调用 has_if <- Lst[Sym foo  Num 1  Lst[Sym bar  Sym a]]     ← 最外层
调用 has_if <- Sym foo                                       ← 元素①
调用 has_if <- Num 1                                         ← 元素②
调用 has_if <- Lst[Sym bar  Sym a]                           ← 元素③，又是 Lst，继续下降
调用 has_if <- Sym bar
调用 has_if <- Sym a
```

### ⭐ 关键：递归「变小」发生在**树的深度**上，不是列表长度上

`type s_exp = … | Lst of s_exp list` **引用了自己**，所以 `s_exp` 是一棵**树**：

| 谁负责什么 |
|---|
| **`List.exists`** —— **横向**走完一层的所有兄弟节点 |
| **`has_if`** —— **纵向**往子树里下降一层 |

**分工完全分开**，所以 `has_if` 自己不需要拆列表——那件事外包给了 `List.exists`。
终止性：每次下降子树严格小一层，`Sym`/`Num` 是叶子。空表也没问题（`List.exists f [] = false`）。

## 18.4 同一个形状的第二个例子：汇总型遍历

他随后又带回一张截图：

```ocaml
| Lst l -> List.fold_left ( + ) 0 (List.map total l)
```

拆开跑（`Lst [Num 1; Num 2; Lst [Num 30; Sym "x"; Num 400]]`）：

```
List.map total l        →  [1; 2; 430]      ← 每棵子树先各自算成一个 int
List.fold_left (+) 0 …  →  433              ← 再把这些 int 加起来
```

**分工和 `has_if` 完全一样**，区别只在横向那步用什么：

| | 横向用什么 | 因为要 |
|---|---|---|
| `has_if` | `List.exists` | **有一个满足就够**（bool） |
| `total` | `List.map` + `fold_left` | **全部收拢成一个数**（int） |

> **这两个例子把「AST 遍历」讲全了：判断型 + 汇总型。**
> `ocaml-compiler-lab/lib/interp.ml` 的 `eval` 是第三种——**变换型**。
> **这是他最终目标的核心形状，值得反复回收。**

## 18.5 用户主动问的：`(+)` 是什么

截图里 `List.fold_left ( + ) 0 …` 的 `(+)`。

**不是新用法**——就是 17.10 讲过的「运算符加括号 = 当普通函数值用」。

```
( + ) : int -> int -> int = <fun>
```

**能起名、能部分应用**（「函数是值」+「柯里化」的直接兑现）：

```ocaml
let plus = ( + )      (* int -> int -> int *)
let inc  = ( + ) 1    (* int -> int *)
inc 41                (* → 42 *)
```

`fold_left` 要的正是一个二元函数，`(+)` 正好塞进去。
**`fold_left (+) 0` 就是「求和」的标准写法**（标准库没有 `List.sum`）。

⚠️ 复现了一次已知的坑：**只有 `*` 需要空格**（`(*)` → `Comment not terminated`），
`(+)` 不需要。**但统一都加空格，记一条规则比记一个例外省事。**

## 18.6 ⛔ 讲到哪了

**已讲**：`function`、嵌套模式、s_exp 的两种遍历、`(+)` 当函数值。

**⬜ D1 还剩**：`when` 守卫、`and` 相互递归、可变记录字段 `<-`、数组。

**用户没有被单独考过这几样**（全程是他提问我讲），**掌握程度无客观依据**。
→ 但 18.1 的 `function` 在 [`ex08_list_stdlib`](../../exercises/ex08_list_stdlib/) 里没考到，
**如果想验，下次可以顺手让他把某个 `match` 改成 `function`。**

## 相关

- [`09-adt-and-pattern-matching.md`](09-adt-and-pattern-matching.md) — 模式匹配的完整基础，9.8 是核心
- [`17-operators.md`](17-operators.md) — 17.10 运算符当函数值、`( * )` 的空格坑
- [`19-list-stdlib.md`](19-list-stdlib.md) — `List.exists` / `fold_left` 等的速查
