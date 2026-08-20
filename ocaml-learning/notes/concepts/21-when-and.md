# 21. 语法小件（二）：`when` 守卫 + `and` 相互递归

> 2026-08-19 在 `ubuntu24-pc` 上讲的，对应 [`../CURRICULUM.md`](../CURRICULUM.md) 的 **D1**。
> 接 [`18-function-and-patterns.md`](18-function-and-patterns.md)（`function` + 嵌套模式）。
>
> **✅ 2026-08-20 已在 `win10-laptop` 重讲完 21.2**（用户 08-19 要求的重播）。
> 重讲效果好：他当场答对了「`and` 粘在哪个 `let` 上」那道题。
> **⬜ 但 21.2 的最后一块（`type … and …` 接 AST）还没讲**，见 21.2 末尾。
>
> **⭐ 2026-08-20 还把 21.1 深挖了一层**（用户连问四轮追到底），
> 产出「**模式活在编译期，守卫活在运行期**」这条统一解释 —— 见新增的 21.1.5。

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

**常量模式只能钉住一个具体值。** 「小于」「长度大于 3」这类条件，**模式语法本身办不到**。

### ⚠️ 一处订正：「在区间内」是例外 —— 模式语法里有区间模式（2026-08-20 补）

> ⚠️ **本节原先写的是「『在区间内』模式语法也办不到」，那句话过头了。**
> 2026-08-20 用一轮多 agent 交叉核对（91 条断言）查出来并实测订正。
> 出发点没错（int 上确实没有区间模式），但**不能推广到整个模式语法**。

> **区间模式（interval pattern）** — `'a' .. 'z'`，**闭区间**（两端都含）。
> **只支持 `char`**；int / float / string 一律报
> `Error: Only character intervals are supported in patterns.`（实测）
> —— **编译器这句话本身就在说 intervals 是被支持的模式形式**，只是限于 char。

```ocaml
let kind c =
  match c with
  | 'a' .. 'z' -> "小写"
  | 'A' .. 'Z' -> "大写"
  | '0' .. '9' -> "数字"
  | _ -> "其他"
```

实测：`kind 'z'` → `"小写"`（闭区间含右端点），`kind '{'` → `"其他"`，**零警告**。

**⭐ 关键：它是一等模式，不是 `when` 那种逃生口 —— 穷尽性检查照样认它。**

```
let f c = match c with 'a' .. 'y' -> 1 | 'A' .. 'Z' -> 2
Warning 8 [partial-match]: this pattern-matching is not exhaustive.
  Here is an example of a case that is not matched: 'z'
```

**编译器从两个区间里精确算出漏掉的是 `'z'`** —— 它真的在按区间推理，
**和下一节讲的「`when` 把整支摘出检查」是两回事**。还能绑名字：

```ocaml
| ('a' .. 'z' as ch) -> Char.uppercase_ascii ch     (* 实测可用 *)
```

📌 **这条对他的目标是刚需**：词法分析器认字母/数字就是这么写的。
下一节的结论是「**能用模式表达的就别用 `when`**」——
**char 区间正是那个典型**：别写成 `| c when c >= 'a' && c <= 'z' -> …`，
那样白白关掉一次穷尽性检查。

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
| ① 边界是范围 | 有。**`char` 用区间模式 `'a' .. 'z'` 最优**（保住穷尽性检查）；其余类型只有 `if` / `when` |
| ② **两个位置要相等** | **没有**。模式写不出来 |
| ③ 条件要调用函数才算得出（`String.length s > 3`） | 没有 |
| ④ `try…with` 里按异常携带的数据挑 | ③ 的特例。⚠️ 靠 `Failure` 里的字符串分流是坏味道，说明该定自己的异常 |

## 21.1.5 ⭐ `when` 的语义（2026-08-20 深挖，用户连问四轮）

> **起因**：他提出一个模型 ——「`when` 实质上是 `->` 右边的 `if` 条件，
> 只是简短方便、不需要 else，写在左边而已」。
> **对了一半，而拧正另一半带出了全篇最有价值的一条统一解释。**

### ① 守卫为假 ≠ 掉进虚空，而是**继续往下试**

```ocaml
match n with
| x when x > 10 -> "大"
| x when x > 5  -> "中"
| _ -> "小"

f 20 → "大"    f 7 → "中"    f 1 → "小"      (* 实测 *)
```

**`f 7` 走到了第二支** —— 第一支的模式 `x` 明明匹上了，守卫为假，
于是**整支作废，回到匹配流程继续试下一支**。

**`if` 做不到「退回去重新匹配」。** 准确的 C 对应是 `else if` 链：

```c
if      (匹上模式1 && 守卫1) { … }
else if (匹上模式2 && 守卫2) { … }
else if (匹上模式3)          { … }
```

> **`模式 when 条件` 整体构成「这一支的匹配条件」**：模式匹上 **且** 守卫为真。
> **任一个不成立 = 这一支没匹上，继续试下一支。**

### ② 他的第二版模型：「`when` 把范围劈开，落选的合并到后面的模式」

**方向对了，但「劈开」暗示这是编译期的静态集合运算。它不是。** 两个实测反证：

```ocaml
(* 反证 A：落选的可能谁都接不住 —— 不是「合并」，是「继续试，试不着就摔」 *)
let f n = match n with x when x > 10 -> "大"
编译期 → Warning 8: All clauses in this pattern-matching are guarded.
运行期 → f 20 = "大"；f 5 = Exception: Match_failure

(* 反证 B：那个「范围」根本不是固定集合 *)
let thresh = ref 10
let f n = match n with x when x > !thresh -> "大" | _ -> "小"
f 15 → "大";  thresh := 20;  f 15 → "小"      (* 同一个值，结果变了 *)
```

### ③ ⭐⭐ 统一解释（讲到这里他通了，以后直接用这句）

> **模式活在编译期，守卫活在运行期。**

| | 编译期能不能算 | 后果 |
|---|---|---|
| **模式**（含 `'a' .. 'z'` 区间） | ✅ 一个**静态确定的值集合** | 能查覆盖、能查重叠、能指出漏了哪个值 |
| **守卫 `when`** | ❌ 一段**任意 bool 表达式** | 判定它等价于停机问题 —— 编译器只能弃权 |

**所以「能用模式表达的就别用 `when`」不是风格偏好：
你每写一个 `when`，就把那一支从编译期挪到了运行期。**

### ④ 代价是**双向**的，这一点容易漏

| | 表现（实测） |
|---|---|
| **假警报** | `n > 0` / `n <= 0` 数学上穷尽 int，运行也全对，**照样 Warning 8** |
| **真漏洞** | 真漏了也是同一句 Warning 8 → 运行期 `Match_failure` |

**两面合起来才是危险**：因为①你学会无视 Warning 8，等②真来的时候也不会看了。
⚠️ 而且本项目 `exercises/dune` 设了 `-warn-error -a`，**Warning 8 不拦构建**。

编译器的措辞很实在，两种情况分得很清：
- 有未覆盖的构造器：`Some _` + `(However, some guarded clause may match this value.)`
- 所有分支都带守卫：`All clauses in this pattern-matching are guarded.`

### ⑤ 顺带收掉的一道设计题：词法分析器的 `ident_start`

问他「`'0' .. '9'` 要不要放进认标识符**首字符**那一支」，他答「可以，因为它们是连续的
字符序列而不是真的数字」。**观察对（区间模式确实成立），但落错了层**
—— 问的是词法**设计**上该不该，不是语法上能不能。

```ocaml
let is_ident_start    c = match c with 'a'..'z' | 'A'..'Z' | '_' -> true | _ -> false
let is_ident_continue c = match c with 'a'..'z' | 'A'..'Z' | '_' | '0'..'9' -> true | _ -> false
```

**放进 `ident_start` 的话 `123abc` 会被当成标识符开头，数字字面量就再也扫不出来。**
几乎每门语言的规范都把这两个集合分开写。**他写词法分析器第一天就会用上这一对。**

## 21.2 ✅ `and` 相互递归（08-19 首讲，**2026-08-20 已重讲**）

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

### ⭐ `and` 粘在**离它最近的那个 `let`** 上（2026-08-20 重讲时新增）

出的检查题（**他答对了**）：

```ocaml
let rec is_even n = if n = 0 then true else is_odd (n - 1)
let helper x = x + 1
and is_odd n = if n = 0 then false else is_even (n - 1)
```

他的回答：「会说 `is_odd` 未定义，因为它和 `helper` 黏在一起了。」**完全正确。**
实测报错就在第 1 行 `Unbound value is_odd`。

> **推论：一组里的函数必须挨着写。中间插任何一条 `let` 都会把组切断。**

⚠️ 还有一层他没提到、但值得点出来：那一组 `let helper … and is_odd …`
**没有 `rec`**，所以 `is_odd` 的函数体里**连它自己都看不见**，更谈不上相互递归。

### C 对照（重讲时用的，效果好）

| | C | OCaml |
|---|---|---|
| 手段 | **前向声明** —— 先单独把名字放进作用域 | **绑定组** —— 把定义打包，一起生效 |
| 代价 | 声明和定义写两遍，改签名要改两处 | 两个函数必须**挨在一起写** |

> C 是「**先报名，后到场**」；OCaml 是「**一起报名，一起到场**」。

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

**「右边一律用旧环境」听着像限制，其实是它唯一的用途 —— 一次交换**。
⭐ **2026-08-20 重讲时加的对照（他一看就通）**：写成两条 `let` 就是 C 里那个经典 bug ——

```ocaml
let x = 1 and y = 2
let x = y and y = x     →  x=2, y=1     ✅ 同时赋值
(* 对照：写成两条 *)
let x = y               →  x=2
let y = x               →  y=2          ❌ 两个都成 2（实测）
```

```c
x = y;
y = x;    /* 错：x 已经被改了，这里读到的是新值 —— C 里得加临时变量 */
```

**不带 `rec` 的 `and` 天然就是「同时赋值」。**

原始演示：

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

## 21.2.9 ⬜ 还没讲：`type … and …`（重讲时没走到这里）

**2026-08-20 重讲 21.2 时讲到「`rec` 有无语义相反」为止，用户下班了。**
下面这块（`and` 用在 `type` 上、接他的 AST 目标）**下次接着讲**，内容见上面那一节
「⭐ 这东西在他的目标里是刚需」，**照着走即可**。

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
