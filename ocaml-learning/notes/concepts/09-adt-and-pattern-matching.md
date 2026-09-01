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

## 9.8 ⭐ 2026-08-08 的大补强：`match` 从头讲一遍

> **起因**：用户说「我对模式匹配的了解很有限，这道题完全答不上来」，
> 接着又说「你还是先说一下 match 的基本写法和常见写法用法吧，
> 在模式匹配里拆列表这块在我的逻辑里有很多问题，根本讲不通」。
>
> **诊断（我的锅）**：列表模式**同时干了两件事**，而他两件都没单独见过，我直接上了叠加态。

### ⭐⭐ 关键分解：模式有两个独立的能力

| 能力 | 干什么 |
|---|---|
| ① **分辨形状** | 这个值是哪一种？走哪条分支？ |
| ② **取出数据** | 把里面装的东西掏出来绑成名字 |

| 模式 | ① | ② |
|---|---|---|
| **常量** `0` / `"yes"` | ✅ | ❌ |
| **元组** `(a, b)` | ❌（只有一种形状） | ✅ |
| **列表** `x :: rest` | ✅ | ✅ ← **两个叠在一起，这就是他卡住的原因** |

**讲法：先用常量讲①，再用元组讲②，最后回列表看叠加。** 这个顺序有效。

### 9.8.1 `match` 基本形状 = 带返回值的 switch

```ocaml
match 要检查的东西 with
| 模式1 -> 结果1
| 模式2 -> 结果2
```

**对着 C 的 `switch` 讲，四个区别（全部实测）：**

| | C `switch` | OCaml `match` |
|---|---|---|
| **是什么** | **语句**，没有值 | **表达式，有值** |
| **fall-through** | 有，必须写 `break` | **没有**，匹配上一条就结束 |
| **漏掉情况** | 默认不管 | **Warning 8，还点名** |
| **能匹配什么** | 只有整型常量 | 整数、**字符串**、bool… |

### 9.8.2 分支类型必须一致 —— 这是"它是表达式"的**后果**，不是额外规定

```
match n with 0 -> "zero" | _ -> 99
Error: The constant 99 has type int but an expression was expected of type string
```

> **`match` 是表达式，整个表达式必须有一个确定的类型；分支是它可能的取值，所以必须同类型。**
> **C 的 `switch` 是语句、没有值，所以这个要求在 C 里根本不存在。**

**同一条规则在 `if` 上也成立**，而且解释了那个经典报错：

```
if true then 1 else "a"   →  Error: This constant has type string but ... int
if true then 1            →  Error: ... expected of type unit
                             because it is in the result of a conditional with no else branch
```

**没写 `else` 就等于 `else ()`，所以 `then` 那支必须是 `unit`** ← 这就是 10.5 里 `countdown` 写 `if n <= 0 then ()` 的原因。

### 9.8.3 ⭐ 用 C 摊开「模式为什么能拆」（**这一段最有效，务必复用**）

用户的两个问题：
① 自定义的名字 `x` / `rest` 凭什么表示"拆列表"？
② 分支里根本没出现 `lst`，怎么知道拆的是它？

**答案：**
① **不是名字在起作用，是 `::` 在起作用。**

```
x :: rest
↑    ↑↑   ↑
空位 骨架  空位
```

- **`::` / `[]` 是构造器**，固定的，**不能改**（实测把 `::` 换成 `++` → `Syntax error`）
- **`x` / `rest` 是空位**，你起名（实测改成 `head` / `tail` 照跑）

② **`match lst with` 那一行就是在指定要拆谁**，像 C 的 `switch (x)`，`case` 里不会再写一遍 `x`。

**编译器生成的东西（实测编译跑过，代码在 `scratch/pattern_as_c.c`）：**

```c
int sum(struct node *lst) {
    if (lst == NULL) {                      /* | []        形状① */
        return 0;
    } else {                                /* | x :: rest 形状② */
        int          x    = lst->head;      /*   ← x 的全部来历 */
        struct node *rest = lst->tail;      /*   ← rest 的全部来历 */
        return x + sum(rest);
    }
}
```

| OCaml | 生成的 |
|---|---|
| `match lst with` | 「以下检查都针对 `lst`」 |
| `\| [] ->` | `if (lst == NULL)` |
| `\| x :: rest ->` | `else { int x = lst->head; node *rest = lst->tail; … }` |
| `\| _ :: rest ->` | 同上，**但不生成 `x` 那行** |

> **不写模式 = 不生成那两行 = 没有名字可用。** 实测：
> `| _ -> 1 + length rest` → `Error: Unbound value rest`

⏱ **时机（必须标注）**：**哪个名字绑到哪个字段 = 编译期**；**实际走哪条分支 = 运行期**。

### 9.8.4 ⭐ 位置决定方向：模式 vs 表达式 ≈ C 的 lvalue / rvalue

用户猜「是不是语言设计者权衡后决定左边是拆」。**不是，是位置本身决定的。**

| `x :: rest` 出现在 | 方向 | 含义 |
|---|---|---|
| `->` **右边**（表达式位置） | **造** | 把 `x` 接到 `rest` 前面，得到新表 |
| `->` **左边**（模式位置） | **拆** | 判非空；头叫 `x`，尾叫 `rest` |

- 右边是**表达式**：会被**求值**，产生一个值
- 左边是**模式**：**完全不求值**，只是形状描述

「往头部追加」本身就是"算出一个新值"——那是表达式的活。**在模式位置不是被禁止，是无从谈起。**

> **C 里一模一样的区分：`*p = *q;` 左边是写、右边是读。你不会问"设计者为什么决定左边的 `*p` 是写"——因为左边那个位置就是写的位置。**
> **OCaml 的 模式/表达式 和 C 的 lvalue/rvalue 是同一类事：位置决定角色。**
> （这张 `*p` / `*p = v` 对照表他在知识点 8 见过，是已验证有效的锚点。）

**ex03 TODO 3 正好一拆一造：**

```ocaml
| x :: rest -> (x * 2) :: double_all rest
  └── 拆 ──┘   └────── 造 ──────┘
```

### 9.8.5 模式里能写什么（**订正一个说法**）

我先说过"模式里只能出现构造器"，**用户追问后订正**：不止。

| 能写 | 作用 | 例子 |
|---|---|---|
| **构造器** | **判形状** | `[]`、`x :: rest`、`Circle r`、`true` |
| 变量名 | 占空位、起名 | `x`、`rest`、`other` |
| `_` | 占空位、不起名 | `_` |
| 常量 | 判相等 | `0`、`"yes"` |
| ❌ **函数调用** | —— | `a @ b` / `List.cons (x, r)` → **Syntax error** |

**准确说法：想「分辨是哪一个构造器」只能写构造器；但你可以选择不分辨。**
实测 `match c with x -> x` 一个构造器没写也合法，**而且类型退化成 `'a -> 'a`**
——**构造器才是把类型钉死的那个东西**。

### 9.8.6 ⭐ 为什么函数不能进模式：**构造器留痕迹，函数不留**

> `Circle 2.0` 造出的值**内存里带着 tag**说"我是 Circle"，所以能反查。
> `[1] @ [2; 3]` 算完就是 `[1; 2; 3]`，**没有任何痕迹**记录"我是 `@` 出来的、左边曾经是 `[1]`"。

另一个说法（也有效）：**模式要反推，构造器一一对应，函数不是**。
`a @ b` 匹配 `[1;2;3]` 有四种解（`[]/[1;2;3]`、`[1]/[2;3]`、`[1;2]/[3]`、`[1;2;3]/[]`），无解可选。

⏱ 这个限制是**编译期**的：编译器必须能确定"这个名字去读哪个字段"。

> **接他的编译器目标**：正因为模式里只能是构造器，`match` 才能编译成
> **跳转表 + 固定偏移的字段读取**，穷尽性检查也才做得了。

### 9.8.7 `(::)` 前缀形式能用（证明 `::` 就是普通构造器）

```
(::) (1, [2; 3])                    →  [1; 2; 3]          (表达式位置)
match lst with (::) (x, rest) -> …  →  ✅                  (模式位置)
```

**能写但没人这么写**，标准写法就是 `x :: rest`。它的用途是**证明 `::` 不特殊**。

### 9.8.8 不要值的时候：每个空位填 `_`

```ocaml
| Circle _ -> "圆"           | Rect (_, _) -> "矩形"      | Rect _ -> "矩形"   (整个盖住)
| [] -> "空"                 | _ :: _ -> "非空"
| _, _ -> "是个二元组"
```

⚠️ **空位不能整个省掉**：`match s with Circle -> …` →
`Error: The constructor Circle expects 1 argument(s), but is applied here to 0`

⚠️ **起了名字却不用，在 dune dev profile 下直接编译失败**：
`Error (warning 27 [unused-var-strict]): unused variable r`
（练习目录里特意关掉了）。
→ **`_` 和 `ignore (...)`、`_program` 是同一个家族：「我知道，故意的」。**

### 9.8.9 `_` 兜底 vs `_ :: _` —— 意义不同，结果可能相同

- **`_` 表达的是「前面几条都没匹配上的所有情况」**，它等于"非空"**纯粹是因为 `[]` 在上面被挡掉了**
- **`_ :: _` 自己就在说"非空"**，与位置无关

实测顺序一换就出事：

```
match lst with _ -> "任何" | [] -> "空"
Warning 11 [redundant-case]: this match case is unused.
```

> **`_` 从来只有一个意思：匹配任何值、不起名字。「剩余情况」是分支顺序给的效果，不是 `_` 自带的。**

### 9.8.10 `bool` / `unit` 也是普通 ADT

```
let f b = match b with true -> 1
Warning 8 [partial-match]: ... a case that is not matched: false
```

`bool` 定义等价于 `type bool = false | true`，`()` 是 `unit` 的唯一构造器。
**"构造器"不是高级概念——他从第一天写 `true` 就在用了。**

### 9.8.11 元组模式（用来单独演示②）

```ocaml
| (a, b) -> a + b        | a, b -> a + b        (括号可省，逗号才是造元组的)
| (_, b) -> b            | (_, b, _) -> b
```

**元组只有一种形状**，两个后果：

1. **`match` 可以整个省掉**：`let add3 (a, b) = a + b`、`let x, y = (10, 20)`
   （列表不行——还有 `[]` 没覆盖，会 Warning 8）
2. **元数是类型的一部分**，写错编译期就拦：
   `(a, b, c)` 用在二元组上 → `Error: This expression has type 'a * 'b but ... 'c * 'd * 'e`

### 9.8.12 C# 对照（**在本机 .NET 8 实测跑通**）

用户主动问「是不是像 C# 里 `is` 判断然后转型」。**是，而且 C# 就是从 ML 借的。**

```csharp
if (o is Circle) { var c = (Circle)o; … }      // C# 7.0 之前：两步
if (o is Circle c) { … }                        // C# 7.0：一步 = ①判形状 + ②起名字

static double Area(Shape s) => s switch {       // C# 8.0：switch 表达式（有返回值！）
    Circle c => …, Rect r => …, _ => 0.0 };

Circle(var r)      => …                          // C# 8.0 位置模式 ← 就是 | Circle r ->
[var x, .. var rest] => …                        // C# 11 列表模式 ← 就是 x :: rest
```

| OCaml | C# | 版本 |
|---|---|---|
| `match s with` | `s switch { … }` | 8.0 |
| `\| Circle r ->` | `Circle(var r) =>` | 8.0 |
| `\| _ ->` | `_ =>` | 8.0 |
| `\| [] ->` / `\| x :: rest ->` | `[] =>` / `[var x, .. var rest] =>` | 11 |

**⭐ 关键差别 —— 正是 9.4 的「封闭 vs 开放」在两个真语言上的对照。** 实测：

```
s switch { Circle c => …, Rect r => … }        // 两个构造器写全，不写 _
warning CS8509: The switch expression does not handle all possible values
                of its input type (it is not exhaustive).
```

**C# 仍然警告**，因为 `Shape` 的子类是**开放的**（谁都能再继承一个）；
OCaml 的 `type shape = … | …` **写在那儿就这么多**，所以零警告。
→ **C# 的 switch 表达式几乎永远得写 `_`，那个 `_` 又废掉穷尽性检查**——和 C 的 `default:` 同一个困境。
→ 想在 .NET 上要真封闭变体得用 **F#**（有真正的可辨识联合）。

**第二个差别：机制不同**

| | 靠什么分辨 |
|---|---|
| C# | **运行时类型信息**，`is` 真的去查类型 |
| OCaml | **值里的 tag**，类型编译期就擦除了 |

后果：**C# 能对任意 `object` 问"你是不是 Circle"，OCaml 不能**——
它只在**同一个 ADT 的构造器之间**分辨。（这也是 OCaml 没有反射的原因，同 C。）

---

## ⛔ 讲到哪了（接手必读）

### 已经讲完的

9.1 `type` ≠ typedef｜9.2 构造器 + `of`｜9.3 造值/拆值同形｜9.4 穷尽性检查｜
9.5 vs C tagged union｜9.6 两个坑｜9.7 `_` 是模式｜
**9.8 全部（2026-08-08 的大补强：`match` 基础、①②分解、C 摊开、位置决定方向、
模式能写什么、构造器留痕迹、元组模式、`bool`/`unit` 也是 ADT、C# 对照）**

### ✅ 2026-08-08：**暂停解除，而且模型已经立住了**

用户当天一路追问，最后**自己给出了正确总结**（我只订正了一处措辞）：

> 「左边（模式）的职责是描述形状并起名字，右边（表达式）是算出一个值；
> 往头部追加本质是产生值，所以和模式那个位置的语义冲突。」

**这一段是本知识点最硬的一次进展，详见 `MASTERY.md` 2026-08-08。**

**⛔ 但是：全程一行代码没写。** 下一步**不是继续讲**，是去做
[`../../exercises/ex03_list_recursion`](../../exercises/ex03_list_recursion/main.ml)
和 `ex04_record_variant`。路线见 [`../CURRICULUM.md`](../CURRICULUM.md)。

### ⏸️ 历史：2026-08-06 晚用户曾把整个 ADT 按下暂停（**已解除**）

> 「我想还是先巩固一下基础，ADT 和模式匹配这块还是有点复杂，可以先往后放。」

**第 5 次踩刹车，这次他是对的**——原路线里 ADT 本来就排在**递归**后面。
**重启时从下面「`Rect (w, h)` 那道题」接，9.1–9.7 不用重讲。**

### ✅ 已收：那道挂着的题（**答对**）

用户答「只有 1 合法，2 和 3 携带参数的数量不正确」——**结论和理由都对**。
（答案表见下。）

### ✅ 已补讲：9.3「`| Circle r ->` 里的 `r` 从哪来」

用 9.3 的「造值/拆值形状相同」讲的，并演示把 `r` 改名成 `whatever` / `banana`
结果完全不变，证明**它就是你自己起的新名字**。引入术语**模式变量（pattern variable）**。
**用户对这一段没有异议**——他是在我追问下面这道题时喊的停：

```ocaml
type shape = Circle of float | Rect of float * float
(* 问：| Rect ??? -> 那条分支怎么写？ *)
```

⚠️ 顺带一个实测坑：**OCaml 标识符不能用中文**（想拿「半径」当变量名演示时撞的）：
`Error: Invalid character U+534A in identifier`。演示用 ASCII 名字。

### 原始题面与答案

```ocaml
type shape = Circle of float | Square of float
```

问：下面哪些是合法的 `shape` 值？**答案已实测：**

| | 结果 |
|---|---|
| `Square 5.0` | ✅ `val v : shape = Square 5.` |
| `Circle` | ❌ `expects 1 argument(s), but is applied here to 0` |
| `Circle 2.0 3.0` | ❌ **`Syntax error`**（不是类型错误！因为构造器不是函数） |

### 🔴 还没讲的（**都已排进 [`../CURRICULUM.md`](../CURRICULUM.md)，别自己另排顺序**）

| 内容 | 排在哪 |
|---|---|
| **多态 `'a`** | 阶段 B1（**提到最前**，因为后面所有类型签名都带它） |
| **`option`（`None \| Some x`）** | 阶段 B2 —— 最实用 |
| **异常** | 阶段 B3 |
| `when` 守卫｜或模式 `p1 \| p2`｜嵌套模式｜as 模式｜`function` | 阶段 D1 |
| 记录模式 | 阶段 D1（记录本身已讲，见 `11-records.md`） |

**多字段构造器的拆法（`| Rect (w, h) ->`）已经在 9.8 里讲透了**，不用再单独排。

### ⚠️ 当天的教学失误（**别重蹈**）

用户三次不得不喊停。详见 `MASTERY.md` 同日记录。核心教训：

> **例子里出现未讲过的概念 = 例子选错了。**
> 我拿 `let rec fold` 当「简单例子」，而**递归根本还没讲**——
> 于是他同时面对递归 + ADT + 模式匹配三个新东西。

**下次给例子前，先逐个检查里面用到的每个概念是否讲过。**

---

## 9.9 构造器模式的元数：`File` / `File _` / `File v`（2026-09-01，用户提问）

**起因**：ex10 里 `type entry = File of string * int | Folder of folder`。
他在 TODO 3/5 写了 `| File -> 1`、`| File f -> [f.name]`，都撞了同一个报错。
改完之后**主动回头问了写法规则**，问题问得很准：

> 「它携带的是二元组类型的值，在第三和第四题中的 File 模式不关心它携带的值，
> 也必须要在模式 `->` 左边加上一个 `_` 而不能只写 `File` 吗？
> 如果我写 `| File v -> v.fst … v.lst` 类似的写法访问两个值可以吗？」

### 四种写法的实测结果

| 写法 | 结果 | 报错 / 说明 |
|---|---|---|
| `\| File -> "x"` | ❌ | `The constructor File expects 2 argument(s), but is applied here to 0` |
| `\| File _ -> "x"` | ✅ | **一个 `_` 顶掉全部参数**，社区默认写法 |
| `\| File (_, _) -> "x"` | ✅ | 合法但啰嗦，还得数元数 |
| `\| File v -> "x"` | ❌ | `… but is applied here to 1 argument(s)` |

> **元数（arity）** — 构造器携带几个东西。`File of string * int` 元数是 2。

**规则**：模式里要么把每个位置都写出来，要么用**一个光秃秃的 `_`** 顶掉全部。中间状态不行。
`File _` 里的 `_` 不是「一个参数」，是「剩下的全不管」——元数 2 / 5 / 10 都一样写。

### 关键区分：`of t1 * t2` 和 `of (t1 * t2)` 不是一回事

```ocaml
File of string * int      (* 携带【两个】东西 —— 不存在一个二元组可以绑给 v *)
File of (string * int)    (* 携带【一个】二元组 —— 这时 File v 才成立 *)
```

第二种确实能写他设想的形式，实测通过：

```ocaml
type entry2 = File2 of (string * int) | Folder2 of string
let f e = match e with
  | File2 v -> Printf.sprintf "%s/%d" (fst v) (snd v)
  | Folder2 s -> s
(* f (File2 ("a.txt", 10))  →  "a.txt/10" *)
```

### 顺带纠了一处：`v.fst` 不存在

```
Error: This expression has type string * int which is not a record type.
```

**元组不是记录，没有字段名。** `fst` / `snd` 是**普通函数**，写在前面：`fst v`。
⚠️ **只对二元组有效**；三元组以上只能用模式拆。
实际写代码时 `fst`/`snd` 用得不多——**直接在模式里拆更常见**（他 TODO 5 就是这么写对的）：
`| File (name, _) -> [ name ]`。

### 附带（他是看内核的，这条有感觉）

```ocaml
type a = A of int * int      (* Obj.size = 2：两个值直接排在块里 *)
type b = B of (int * int)    (* Obj.size = 1：块里一个指针，指向另一个二元组块 *)
```

**默认不加括号**：少一层间接、少一次分配。加括号只在确实要把元组当整体传来传去时才有意义。

### 教学备注

这一问属于「**语法边角**」，但**是他撞上之后主动问的**，不是我提前展开的
——符合方针里「语法边角只在挡路时讲」。回答用了「四种写法各编译一次」的形式，
每种都给了编译器原话，比讲规则有效。
