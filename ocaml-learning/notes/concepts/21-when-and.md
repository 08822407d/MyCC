# 21. 语法小件（二）：`when` 守卫 + `and` 相互递归

> 2026-08-19 在 `ubuntu24-pc` 上讲的，对应 [`../CURRICULUM.md`](../CURRICULUM.md) 的 **D1**。
> 接 [`18-function-and-patterns.md`](18-function-and-patterns.md)（`function` + 嵌套模式）。
>
> **🔴🔴 21.2（`and`）用户没消化完** —— 他原话：「今天我比较疲劳了，
> **`and` 这部分教学没有仔细看完**，明天在工作机上继续时你还得再讲一遍。」
> **→ 下次开工必须重讲 21.2，别当讲过了。** 21.1（`when`）他接受了，不用重讲。

## 21.1 `when` 守卫

### ⭐ 切入点：用他自己 ex05 写过的 `repeat`

他 2026-08-10 第一版写的是：

```ocaml
match n with 0 -> [] | _ -> x :: repeat x (n - 1)
```

**能过全部测试，但 `repeat 7 (-1)` 无限递归**（题目要的是 `n <= 0`）。
他当时是**换成 `if n <= 0` 绕过去的**，没在 `match` 上纠缠
（[`ex05_poly_exn/main.ml:40`](../../exercises/ex05_poly_exn/main.ml) 里躺着的是改过的版本）。

⚠️ **他对这段完全没印象了**（九天前，而且那个坑只留在 `MASTERY.md` 里没进文件）。
**讲的时候要直接把文件行号贴给他**，别指望他记得。

`when` 是第三条路 —— 保住 `match` 的形状，同时挡住一个**范围**：

```ocaml
match n with
| n when n <= 0 -> []
| _ -> x :: repeat x (n - 1)
```

实测 `repeat 7 (-1)` → `[]`。

> **守卫（guard）** — `模式 when 条件 ->`。**先按模式匹，匹上了再算 `when` 后面那个 bool**；
> 为真才走这一支，**为假就当没匹上，继续往下试**。

### 📌 判据：边界是一个「点」还是一个「范围」

| | 边界 | 该用什么 |
|---|---|---|
| ex09 的 `safe_div`，`b = 0` | **一个点** | `match b with 0 -> None \| _ -> …` ✅ 他自己就是这么写的 |
| ex05 的 `repeat`，`n <= 0` | **一个范围** | 常量模式够不着 → `if` 或 `when` |

**常量模式只能钉住一个具体值。** 「小于」「在区间内」「长度大于 3」这类条件，
**模式语法本身办不到**。

### ⚠️⚠️ 代价：带守卫的分支退出穷尽性检查

```ocaml
let sign n = match n with
  | n when n > 0  -> "正"
  | n when n <= 0 -> "非正"
```

数学上显然覆盖了全部 int，但（**实测**）：

```
Warning 8 [partial-match]: this pattern-matching is not exhaustive.
  All clauses in this pattern-matching are guarded.
```

**穷尽性检查是编译期做的，只看模式的形状。** `n > 0` 是**运行期**才算得出来的表达式，
编译器不会去证明两个守卫恰好互补 —— 那等于要求它做定理证明。

> **每加一个 `when`，就把那一支从穷尽性检查里摘出去了。**

⭐ **这一条正好接 20.6**：`option` 值钱是因为漏一支编译器会点名告诉你；
**`when` 用一次，就在那一支上把这个保护关掉一次**。→ **能用模式表达的就别用 `when`。**

**修法**（他没答，我直接给的）：**最后一支不要带守卫**。

```ocaml
| n when n > 0 -> "正"
| _ -> "非正"              (* ← 纯模式，编译器看得懂它覆盖了剩下全部 *)
```

### 能用在哪：只有「match 分支」，但那出现在三个地方

```ocaml
match e with | p when c -> …               (* ① match *)
function     | p when c -> …               (* ② function（见 concepts/18） *)
try e with   | Failure m when m = "轻" -> …  (* ③ try…with —— with 后面就是 match 分支 *)
```

③ 实测：守卫为假时**异常没被接住，继续往外抛**。（延续 14.3「`with` 后面就是 `match`」。）
**`let` / `fun` / `for` / `while` 里都没有 `when`。**

### ⭐⭐ `when` 真正的存在理由：模式里不能重复用同一个名字

```
match p with (x, x) -> true | _ -> false
                  ^
Error: Variable x is bound several times in this matching
```

**模式的工作是「造名字」，同一个名字造两遍是矛盾的**（9.8「位置决定方向」）。
所以「这个二元组的两半一样吗」**用模式根本写不出来**：

```ocaml
match p with (x, y) when x = y -> true | _ -> false     ✅ 实测可用
```

> **模式语言是故意做窄的**（窄才能做穷尽性检查），窄了就总有表达不了的条件
> —— `when` 是那个逃生口。**这是它存在的真正理由，不是「更灵活的边界」。**

### 常用场景小结

| 场景 | 有没有替代品 |
|---|---|
| ① 边界是范围 | 有（`if`）。选 `when` 是为了保住 `match` 的形状 |
| ② **两个位置要相等** | **没有**。模式写不出来 |
| ③ 条件要调用函数才算得出（`String.length s > 3`） | 没有 |
| ④ `try…with` 里按异常携带的数据挑 | ③ 的特例。⚠️ 靠 `Failure` 里的字符串分流是坏味道，说明该定自己的异常 |

## 21.2 🔴 `and` 相互递归（**用户没消化完，下次重讲**）

### 问题本身（实测）

```
let rec is_even n = if n = 0 then true else is_odd (n - 1)
                                            ^^^^^^
Error: Unbound value is_odd
```

**根因**：OCaml 的 `let` 是**顺序**生效的 —— 一个名字要到它自己那条 `let` 写完之后
才进入作用域。**`rec` 只多干一件事：让名字在自己的函数体里提前可见**（所以能调自己），
**但它管不到下一条 `let`**。

### 锚点：C 的前向声明

```c
int is_even(int n) { return n == 0 ? 1 : is_odd(n - 1); }  /* is_odd 还没声明 */
int is_odd (int n) { return n == 0 ? 0 : is_even(n - 1); }
```

C 的解法是**前向声明**（先写个原型，把名字提前放进作用域）。
**OCaml 没有前向声明** —— 它的解法是把两个函数**绑成一组，一起生效**：

```ocaml
let rec is_even n = if n = 0 then true  else is_odd  (n - 1)
and     is_odd  n = if n = 0 then false else is_even (n - 1)
```

实测 `is_even 10` → `true`，`is_odd 10` → `false`。

> **`let rec A = … and B = …`** — 一个绑定组，**组内所有名字对组内所有函数体同时可见**。
> 不是「A 然后 B」，是「A 和 B 一起」。

**只有第一个写 `let rec`**，后面接 `and`，中间**没有 `in`**（顶层）。

### ⚠️⚠️ 同一个 `and`，带不带 `rec` 语义相反

| 写法 | 含义 | 右边能看见组内其他名字吗 |
|---|---|---|
| `let rec f = … and g = …` | **相互递归** | ✅ 能 |
| `let a = … and b = …` | **并列绑定** | ❌ **不能**，右边一律用**旧**环境 |

```
let a = 1 and b = a + 1;;
                  ^
Error: Unbound value a          ← 实测
```

**「右边一律用旧环境」听着像限制，其实是它唯一的用途 —— 一次交换**：

```ocaml
let x = 1 and y = 2      (* x=1, y=2 *)
let x = y and y = x      (* x=2, y=1  ← 实测，两边都读的是旧值 *)
```

**判据：看有没有 `rec`。**

### ⭐ 这东西在他的目标里是刚需

`and` 不只用于 `let`，**`type` 也能用**（实测）：

```ocaml
type expr = Num of int | Call of string * expr list | Block of stmt list
and  stmt = Assign of string * expr | If of expr * stmt list
```

**表达式里能套语句块，语句里能套表达式** —— 任何真实语言的 AST 都躲不掉这个形状。
**没有 `and` 连类型都定义不出来。** 遍历它的函数也必然成对出现：

```ocaml
let rec eval_expr e = … eval_stmt … 
and     eval_stmt s = … eval_expr …
```

**这就是他目标项目 `~/projs/ocaml-compiler-lab/lib/ast.ml` 里
`let rec show = … and show_binop = …` 的由来** —— 不是风格选择，
**是被数据结构的形状逼出来的**。

## 21.3 ⛔ 还没讲的（D1 剩下的）

- **可变记录字段 `<-`**
- **数组**

这两件放一起讲比较顺（都属于「OCaml 里怎么搞可变状态」），而且**都是他在 C 里天天用、
OCaml 社区不太用**的东西。

## 相关

- [`18-function-and-patterns.md`](18-function-and-patterns.md) — D1 的前一半（`function` + 嵌套模式）
- [`09-adt-and-pattern-matching.md`](09-adt-and-pattern-matching.md) — 9.8「位置决定方向」，21.1 直接用了
- [`20-option.md`](20-option.md) — 20.6 穷尽性检查的价值，21.1 的代价那节是它的反面
- [`03-let-in-scope.md`](03-let-in-scope.md) — `let` 的作用域，21.2 的前置
- [`10-recursion.md`](10-recursion.md) — `rec` 是干什么的
