# 9. 代数数据类型（ADT）与模式匹配

> 2026-08-06 开讲，**尚未讲完**。起因是用户从伯克利公开课带回
> `type fabric = Linen | Cotton | Wool` 问「`type` 是不是 typedef」。
>
> ⚠️ **接手前必读文末的「⛔ 讲到哪了」**——这一篇是**进行中**的，
> 而且当天在这个知识点上出过一次明显的教学节奏失误，别重蹈。

---

## 9.1 `type` 不是 typedef

**同一个关键字干两件事，取决于等号右边：**

```ocaml
type myint = int                       (* 别名，等价于 C 的 typedef *)
type fabric = Linen | Cotton | Wool    (* 造一个新类型 + 三个新值 *)
```

第二种造出来的东西**不是数字**：

```
Linen = 0
Error: The constant 0 has type int but an expression was expected of type fabric
```

| | 造出了什么 | 类型安全 | 编译器知道有几种吗 |
|---|---|---|---|
| C `typedef int myint;` | 别名 | 无 | — |
| C `enum { RED, ... }` | **整数常量** | 无（能算术、能和 int 混用） | 不知道 |
| OCaml `type fabric = …` | **新类型 + 三个值** | **有** | **知道，恰好三种** |

## 9.2 构造器

> **构造器（constructor）** — 造出某个类型的值的名字。**首字母必须大写**（语法规定，
> OCaml 靠大小写区分构造器和普通变量名）。

**光杆构造器本身就是值：**

```ocaml
type color = Red | Green | Blue
let c = Red        (* val c : color = Red *)
```

**带 `of` 的构造器是个「模子」，要填空才成为值：**

```ocaml
type shape = Circle of float | Square of float
let a = Circle 2.0     (* ✅ val a : shape = Circle 2. *)
let b = Circle         (* ❌ The constructor Circle expects 1 argument(s),
                              but is applied here to 0 argument(s) *)
```

### ⚠️ 构造器**不是函数**（实测三条）

```ocaml
let f = Add              (* ❌ expects 2 argument(s), applied to 0 —— 不能部分应用 *)
Circle 2.0 3.0           (* ❌ Syntax error —— 注意是「语法」错误！*)
```

第二条特别说明问题：**如果 `Circle` 是函数，多给一个参数会是类型错误；
它报语法错误，说明构造器压根不参与「函数应用」那套语法。**

### ⚠️ `of A * B` 是「两个参数」，不是「一个元组」

```ocaml
type t  = Add  of int * int      (* 两个参数 *)
type t2 = Pair of (int * int)    (* 一个参数，那个参数是元组 *)

let g p = Pair p                 (* val g : int * int -> t2 —— 能这样传 *)
```

`Add (1, 2)` **长得像**传元组，其实是「给两个参数」。写代码时区别不大，
但知道这一点才解释得通为什么 `Add` 不能像函数那样被部分应用。

## 9.3 造值 vs 拆值：形状一样

**这是理解模式匹配的钥匙。**

```ocaml
type shape = Circle of float | Rect of float * float

let area s =
  match s with
  | Circle r -> 3.14 *. r *. r
  | Rect (w, h) -> w *. h
```

```
造：  Circle 2.0          拆：  Circle r
造：  Rect (3.0, 4.0)     拆：  Rect (w, h)
      ↑ 填具体的值              ↑ 填名字，用来接住里面的值
```

**形状完全相同**，唯一区别是造值填**值**、拆值填**名字**。
`match` 做的事就是：看这个值是哪种形状，然后把里面装的东西取出来给你用。

（元组那里已经见过同样的对称性：`"61C", "164", 130` 造，`"61C", "164", _` 拆。）

## 9.4 穷尽性检查：ADT 的核心价值

> **穷尽性检查（exhaustiveness checking）** — 编译器验证 `match` 覆盖了所有情况，
> 没覆盖就报 `Warning 8`，**并举出一个没匹配到的例子**。

```
Warning 8 [partial-match]: this pattern-matching is not exhaustive.
  Here is an example of a case that is not matched: Wool
                                                    ↑ 直接点名
```

**封闭 vs 开放**——这是全部价值所在：

| | 可能的值 | 写全了会怎样 | 打错字 |
|---|---|---|---|
| `fabric`（ADT） | **恰好三种** | **零警告**，编译器证明你覆盖完整 | `Linnen` → 编译错误 |
| `string` | **无限种** | **永远消不掉 Warning 8** | `"Linnen"` → 静默落进 `_` |

### 警告还是错误？取决于编译选项（实测）

| 编译方式 | 提示词 | 生成 `.cmo` 了吗 |
|---|---|---|
| 默认 | `Warning 8` | ✅ 编译通过 |
| `-warn-error +8` | `Error (warning 8)` | ❌ 编译失败 |

**本项目在 `exercises/dune` 里故意关掉了**（`-warn-error -a`），为了让写到一半的练习也能跑。
但**真实项目里 Warning 8 必须是错误**——放任它只是警告，ADT 的价值就废掉一大半，
退回到运行时才抛 `Match_failure`。

## 9.5 和 C 的 tagged union 对照（用户要求的例子）

C 需要三样东西手动同步；OCaml 一行：

```c
typedef enum { V_INT, V_FLOAT, V_STR } value_tag;
typedef struct { value_tag tag; union { int i; double f; char *s; } u; } value;
```
```ocaml
type value = VInt of int | VFloat of float | VStr of string
```

**实测对照：**

| | C | OCaml |
|---|---|---|
| **读错成员** | `a.u.f` → `2.07508e-322`，**gcc -Wall 一声不吭** | **`Error: The value f has type int...`**，写都写不出来 |
| tag 与 payload 的关系 | 靠程序员自觉 | **语法上绑死** |
| 加一个新变体 | `-Wswitch` 会警告 ✅ | `Warning 8` 会警告并点名 ✅ |
| 加了兜底之后 | `default:` → 警告消失 | `\| _ ->` → 警告同样消失 |

⚠️ **要说公道话**：`-Wswitch` 是 C 里真实存在的穷尽性检查，**这个弱点是对称的**。
真正的差别有两条：

1. **「读错成员」在 C 里没有任何防护，在 OCaml 里根本不是一个能表达的操作** ← 决定性
2. **惯例相反**：C 的很多规范（如 MISRA）**强制要求写 `default:`**，等于废掉 `-Wswitch`；
   OCaml 社区对封闭变体的共识是**不要写 `\| _ ->`**

## 9.6 模式匹配的坑（都实测过）

**根源：`match` 的分支列表贪婪，而且 `match` 没有闭合符号。**

| 坑 | 后果 | 编译器管吗 |
|---|---|---|
| **嵌套 `match`** | 后面的分支被**最内层**抢走 | ✅ Warning 8 + 11 |
| **`match` 后面接 `;`** | 被吃进最后一条分支 | ❌ **零警告，静默出错** ← 最危险 |

判据：**`match` 后面还有东西时才加括号**；函数体最后一个表达式不用加（社区也不加）。
多行时社区偏向 `begin … end` 而不是 `( )`。

三层嵌套实测：**两条兜底分支全都归给了最内层**，外面两层各自只剩一个分支。
归属判据两步：① 语法上接得上吗（`else`/`in`/`)`/`end` 接不上）→ ② 接得上就归**最内层**。
这就是编译原理里 **悬挂 else（dangling else）** 的同一类问题。

## 9.7 `_` 是模式，不是关键字

> **通配符模式（wildcard pattern）** — 匹配任何值、**不绑定任何名字**。

和 C# 的 `default` 完全不同：`default` 是 `switch` 语法的一部分，只能在固定位置；
`_` 是个模式，**可以出现在任意位置、任意多次**（`_, "164", _`）。

**证据**：`_` 放中间照样编译，只是后面的分支永远轮不到（Warning 11）。
如果它是「结束符」，后面就该是语法错误。

**模式出现的地方远不止 `match`：**

| 位置 | 例子 |
|---|---|
| `match` 分支 | `\| _ -> …` |
| **函数参数** | `let f _ = 5` |
| **`let` 的左边** | `let (a, b) = (1, 2)` ← **能解构** |
| `fun` 参数 | `fun _ -> 5` |
| 丢弃返回值 | `let _ = f ()` |

⚠️ **类型位置上的 `_` 是另一个意思**：`(x : _ list)` = 「这个类型你自己推」。

---

## ⛔ 讲到哪了（接手必读）

### 已经讲完的

9.1 `type` ≠ typedef｜9.2 构造器 + `of`｜9.3 造值/拆值同形｜9.4 穷尽性检查｜
9.5 vs C tagged union｜9.6 两个坑｜9.7 `_` 是模式

### 🔴 有一道题挂着，用户没答

```ocaml
type shape = Circle of float | Square of float
```

问：下面哪些是合法的 `shape` 值？**答案已实测：**

| | 结果 |
|---|---|
| `Square 5.0` | ✅ `val v : shape = Square 5.` |
| `Circle` | ❌ `expects 1 argument(s), but is applied here to 0` |
| `Circle 2.0 3.0` | ❌ **`Syntax error`**（不是类型错误！因为构造器不是函数） |

### 🔴 还没讲的（用户明确说「还没弄清楚」）

- **模式匹配怎么把数据取出来** —— 即 `| Circle r -> …` 里 `r` 是从哪来的。
  **9.3 已经写了答案，但用户还没消化**，下次从这里接。
- `when` 守卫｜或模式 `p1 | p2`｜嵌套模式｜递归类型定义｜as 模式
- `option` 类型（`None | Some x`）—— **最实用，优先补**
- `function` 关键字｜列表模式｜记录模式｜多态 ADT

### ⚠️ 当天的教学失误（**别重蹈**）

用户三次不得不喊停。详见 `MASTERY.md` 同日记录。核心教训：

> **例子里出现未讲过的概念 = 例子选错了。**
> 我拿 `let rec fold` 当「简单例子」，而**递归根本还没讲**——
> 于是他同时面对递归 + ADT + 模式匹配三个新东西。

**下次给例子前，先逐个检查里面用到的每个概念是否讲过。**
