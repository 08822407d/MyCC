# 20. `option`：把「可能没有」写进类型里

> 2026-08-18 在 `win10-laptop` 上讲的，对应 [`../CURRICULUM.md`](../CURRICULUM.md) 的 **B2**。
> **这一篇是 2026-08-19 补写的**（当天没留概念笔记，讲法先落在 `MASTERY.md`）。
>
> ⚠️ **这是「重启」**。2026-08-10 第一次开这块时用户要求整块推迟，
> **根因是我拿 C# 可空引用 `string?` 当锚 —— 他自述那玩意儿也不熟**。
> 这次换锚点，一次讲通。**教训：锚点选错 ≠ 知识点难。**

## 20.1 ⭐ 切入点：用他自己写过的笨代码当痛点

他在 [`ex08`](../../exercises/ex08_list_stdlib/) 第 8 题写的是：

```ocaml
try List.find (fun s -> String.length s > 3) lst with Not_found -> "无"
```

> **「找不到就给个默认值」是完全正常的情况，你却为它架了一套异常机制。**

**这个切法有效**，和 `fold` 那次从他自己手写的 `go acc rest` 切进去是同一个套路：
**先让他写出笨版本，再给工具。** 光讲「option 是什么」留不住。

`List.find_opt` 一行就够：

```ocaml
match List.find_opt (fun s -> String.length s > 3) lst with
| Some s -> s
| None   -> "无"
```

## 20.2 锚点用 **C 的 `atoi("abc")`**，⛔ 不要用 C# nullable

```c
int n = atoi("abc");   /* 返回 0 */
int m = atoi("0");     /* 也返回 0 */
```

> **`atoi` 分不出「解析失败」和「值就是 0」** —— 它把失败伪装成了一个合法的结果。

这是他在 C 里见过的真问题（`strtol` 要靠 `errno` + `endptr` 才能区分）。
`int_of_string_opt` 直接把这两种情况分成 `None` 和 `Some 0`，**在类型上就分开了**。

> **`option`（选项类型）** — 一个值要么是 `Some x`（有，里面装着 `x`），
> 要么是 `None`（没有）。**「可能没有」被编码进了类型本身。**

## 20.3 只讲了三样

| | |
|---|---|
| `Some x` | 有值，`x` 装在里面 |
| `None` | 没有 |
| `match o with Some v -> … \| None -> …` | 拆开看 |

**动作和 ex04 拆 `shape` 一模一样，只是换了构造器名。** 他一眼就认出来了。

⛔ **按计划没有写出 `type 'a option = None | Some of 'a`** —— 那是「带参数的类型定义」，
属于 **D1.5**。**别以为讲过了。**（2026-08-10 就是在这里踩空的。）

## 20.4 ⭐ 他自己发现的一个作用域问题（很有价值）

看到上面那段代码他问：

> 「我注意到这里 `s` 出现在 lambda 表达式中，而后面的分支里又用了 `s`，
> **可见性和作用域似乎和我的认知不一样**。」

**答案：那是两个毫不相干的 `s`，作用域根本不重叠 —— 连遮蔽都算不上。**

```ocaml
match List.find_opt (fun s -> String.length s > 3) lst with
                          ↑ 这个 s 活在 lambda 体内，到 ) 就结束
| Some s -> s
       ↑ 这个 s 是分支自己新绑的
```

**两块是平行的，不是嵌套的**（`concepts/03` 的遮蔽讲的是嵌套的情形）。

**实测证据**（两条都当场跑了）：

```ocaml
(fun str -> String.length str > 3)  两处各自改名  →  照常工作
| Some _ -> s                        →  Error: Unbound value s
```

后一条是决定性的：**lambda 里的 `s` 透不进分支**。

## 20.5 ⭐⭐ 他连问三层「`s` 到底是什么」——每一层都问在要害上

| 他问的 | 答案 |
|---|---|
| ①「`\| Some s -> s` 里的 `s` 到底是什么？」 | **左边是「造名字」、右边是「用名字」**（`concepts/09` 9.8「位置决定方向」） |
| ②「`s` 是 `match` 和 `with` 之间那个表达式的结果？」 | **差一步**：那段算出来的是**整个盒子** `Some "abcd"`，`s` 是**盒子里的那一块** |
| ③ 他自己总结：「`Some` 分支带一个值，而这个值是产生 option 的那个表达式在语义上应当得到的结果」 | **准确** |

**②的决定性反证**：`| Rect (w, h) ->` 一次绑**两个**名字，
**不可能两个都等于「那个结果」**。

### 📌 准确说法（以后直接用这一句）

> `match E with 模式 -> …` —— `E` 算出一个值，拿模式去**套**它；
> **模式里每个小写名字，绑到它在模式中所处位置对应的那块数据。**

| 模式 | 名字绑到什么 |
|---|---|
| `\| whole -> …` | 整个值 `Some "abcd"` |
| `\| Some s -> …` | `"abcd"` |
| `\| Rect (w, h) -> …` | `3.` 和 `4.` |

## 20.6 ⭐⭐ `option` 比异常强在哪（**实测对照，这是本篇最值钱的一节**）

```ocaml
(* option：漏一支 *)
let f o = match o with Some n -> n
Warning 8 [partial-match]: this pattern-matching is not exhaustive.
  Here is an example of a case that is not matched: None      ← 还告诉你漏哪支
```

```ocaml
(* 异常：接错名字 *)
let g lst = try List.find (fun x -> x > 99) lst with Failure _ -> 0
val g : int list -> int = <fun>     ← 编译器一声不吭（List.find 抛的是 Not_found！）
g [1;2;3]  →  Exception: Not_found  ← 运行到这里才炸
```

> **差别不在长短，在于「写错了谁发现」。**
> 异常**不在类型里** —— `List.find : ('a -> bool) -> 'a list -> 'a`，
> 签名上看不出它会抛什么，**所以没人帮你数分支**。
> `option` 把「可能没有」写进了返回类型，**类型检查器就能替你数**。

**⚠️ 直接点了他一句**：ex08 那行之所以能跑对，
**纯粹是因为他当时记住了 `Not_found` 这个名字** —— 记错了编译器也不会拦。

**接他的编译器目标**：这就是「把不变量编码进类型」的最小例子。
**能让类型检查器查的，就别留给运行期。**

## 20.7 练习结果：[`ex09_option`](../../exercises/ex09_option/) **18/18 全过**

七题分三部分：① 把 ex05/ex08 的异常版重写（`find_opt` / `int_of_string_opt` / `nth_opt`）
② 只消费（`describe` / `add_opts`）③ **自己生产 option**（`safe_div` / `head_opt`）。

**概念层面七题全对，三处错全是机械性的**：

| 错误 | 性质 |
|---|---|
| `Strng.length` | 笔误（编译器还给了 `Did you mean String?`） |
| **TODO 1、3 漏写 `match`** | **老模式：局部对、整体漏一块**（另外五题都写了） |
| `\| Some val -> val` | **`val` 是保留字**（`.mli` 里声明导出值用的） |
| `"有:" ^ n` | 忘了 `n` 是 `int`，`^` 两边都要 `string` |

**两处值得表扬：**

- **`safe_div` 用了常量模式** `match b with 0 -> None | _ -> …` —— 比 `if b = 0` 更贴 `match` 的味道。
  **而且和 ex05 的 `repeat` 形成对照**：那次 `match n with 0 -> …` 出过问题（负数走不到出口）。
  **判据是「边界是不是一个点」**：`b = 0` 是点，`n <= 0` 是范围 —— 是范围就得用 `when` 守卫或 `if`。
- **`add_opts` 元组模式一次到位**，四种组合只写了要干活的那条，`Some (x + y)` 的括号也没漏。

> 🚩 **那四种错 LSP 全都能当场标红** —— 这直接催生了当天的环境排查
> （悬停看签名 / 库函数说明 / 关掉 AI 补全 / 红波浪线，见 `docs/env/`）。

## 20.8 ⛔ 故意没讲的（**别以为讲过了**）

- **`type 'a option = None | Some of 'a`** —— 类型定义里的 `'a`，属于 **D1.5**
- **`Option` 模块**（`Option.value ~default` / `Option.map` / `Option.bind` / `Option.join`）
  —— 实测可用（`Option.value (Some 3) ~default:0` → `3`），但**一个都没提**。
  `Option.map` 要等他对 `map` 在别的容器上的推广有感觉时再讲
- **`option` 串联的笨拙**（嵌套 `match` 金字塔）和它的解药（`let*` / monadic bind）—— 太远
- **`result` 类型**（`Ok` / `Error`，能带失败原因）—— `option` 的 `None` 不说「为什么没有」
- **性能**：`Some x` 是不是要装箱 —— 他迟早会问（他是写编译器的人），**答案不 trivial**

## 相关

- [`19-list-stdlib.md`](19-list-stdlib.md) — **19.5** 是 `_opt` 系列速查（本篇的直接下游）
- [`14-exceptions.md`](14-exceptions.md) — **14.7** 异常 vs `option` 怎么选
- [`09-adt-and-pattern-matching.md`](09-adt-and-pattern-matching.md) — 9.8「位置决定方向」，20.5 直接用了
- [`13-polymorphism.md`](13-polymorphism.md) — `'a option` 里的 `'a`
