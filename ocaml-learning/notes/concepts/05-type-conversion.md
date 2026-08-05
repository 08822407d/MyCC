# 5. 类型转换：只有显式，而且转换就是普通函数

> 2026-08-05 讲的。这一节是**知识点 2（int/float 无隐式转换）的实用补完**——
> 用户问「OCaml 是不是既没有隐式转换也没有强制类型转换」。
>
> 讲完这节，`ex01_int_float` 那三个 TODO 的知识就全齐了。

## 结论

| 说法 | 判定 |
|---|---|
| 没有隐式转换 | ✅ 对 |
| 没有 C 那种 `(float)x` 强制转换语法 | ✅ 对 |
| 「不能做类型转换」 | ❌ 能做，只是通过**普通函数** |

## 为什么连隐式转换的机会都没有

```
5 + 1.5
Error: The constant 1.5 has type float but an expression was expected of type int
```

根源比「不做提升」更彻底：**`+` 和 `+.` 是两个不同的函数**。

```
+     :  int -> int -> int
+.    :  float -> float -> float
```

`+` 连接收 float 的能力都没有，所以**不存在「编译器要不要帮你提升」这个岔路口**。
C 里 `5 + 1.5` 能跑是因为 `+` 一个符号身兼多职（重载），编译器必须决定怎么统一两边。

## 类型标注不是强制转换

```
(5 : float)
Error: The constant 5 has type int but an expression was expected of type float
Hint: Did you mean 5.?
```

`(表达式 : 类型)` **只检查，不改变**。

## 工具箱

| 要做的事 | 用什么 | 备注 |
|---|---|---|
| int → float | `float_of_int n` | `float n` 是简写别名 |
| float → int | `int_of_float x` | `truncate x` 同义；⚠️ 见下 |
| 向下取整 | `floor x` | **返回 float** |
| 向上取整 | `ceil x` | **返回 float** |
| 四舍五入 | `Float.round x` | **返回 float**，`.5` 朝远离零的方向 |

`Float.of_int` / `Float.to_int` 是模块风格的同义写法。

## ⚠️ 会咬人：`int_of_float` 是「朝零截断」不是「向下取整」

```ocaml
int_of_float   2.7   →   2
int_of_float (-2.7)  →  -2      (* 不是 -3！*)
int_of_float (-2.5)  →  -2
floor        (-2.7)  →  -3.
```

**正数上两者一样，负数上分道扬镳。** 这类 bug 特别难查——测试数据往往全是正数。

另外 `floor` / `ceil` / `Float.round` **返回的都是 float**，要 int 得再套一层：

```ocaml
Float.round 2.5                  →  3.    (* float *)
int_of_float (Float.round 2.5)   →  3     (* int  *)
```

## 实战：两个整数求平均再四舍五入

```ocaml
let avg_round a b =
  int_of_float (Float.round (float_of_int (a + b) /. 2.))
```

每一步的类型变化：

```
a + b                    : int      两个 int 用 +
float_of_int (a + b)     : float    进入浮点世界
... /. 2.                : float    浮点除法用 /. ，除数写 2. 不是 2
Float.round ...          : float    还在浮点世界
int_of_float ...         : int      回到整数世界
```

忘了转换的下场（**报错精确指向出问题的那一格**，这正是「没有隐式转换」换来的好处）：

```ocaml
let avg a b = (a + b) /. 2.
Error: This expression has type int but an expression was expected of type float
                  ^^^^^^^ 指向 (a + b)
```

## ⚠️ 「带点 = 浮点版」只是命名习惯，不是规则

用户提出「操作数必须和运算符的符号一致」，方向对，但按「符号带不带点」去判断会翻车三次：

### 例外一：比较运算符通吃

```ocaml
1 = 1          →  true
1.5 < 2.5      →  true
"abc" = "abd"  →  false
```

同一个 `=`、同一个 `<`，int/float/string 全接，**而且不存在 `=.`**。

```ocaml
let eq x y = x = y   →   val eq : 'a -> 'a -> bool
let add x y = x + y  →   val add : int -> int -> int
```

`'a` 读作「某个类型」。**但两个 `'a` 是同一个字母**，所以两边必须是**同一个**类型：

```ocaml
1 = 1.5
Error: The constant 1.5 has type float but an expression was expected of type int
```

「通吃各种类型」和「两边必须同类型」不矛盾：前者说**能接哪些**，后者说**两边要一致**。

### 例外二、三：长相和类型无关

| 运算符 | 长相 | 实际只吃 | 反例 |
|---|---|---|---|
| `**`（幂） | 不带点 | **float** | `2 ** 3` ❌，要 `2. ** 3.` |
| `mod`（取余） | 不带点 | **int** | `5. mod 2.` ❌ |

`**` 尤其阴——长得完全不像浮点运算符。

## 正确的心智模型

**别看符号长什么样，看它的类型。**

运算符**就是普通函数**，只是写在两个操作数中间。每个函数有固定的类型签名，参数对不上就报错——
这跟 `float_of_int` 不接受 float 是完全一样的一件事，没有任何特殊性。

## ⚠️ `==` 不是 `=`（假朋友，杀伤力最大）

```ocaml
"abc" == "abc"   →  false      (* 物理相等：是不是同一块内存 *)
"abc" = "abc"    →  true       (* 结构相等：内容一样 *)
```

C#/Java 背景的人顺手写 `==` 比较字符串，**编译通过、运行不报错、结果是错的**。

## 顺带：`let` 里那个 `=` 也不是比较

```ocaml
let x = 5 in x = 5     →  true
    ↑            ↑
    │            └─ 比较运算符
    └─ let 语法的一部分，不是运算符
```

同理 `type t = …`、`let f x = …` 里的 `=` 都是语法的一部分。**靠位置区分，不靠符号。**

而且 **`let` 是绑定不是赋值**。OCaml 真正的赋值要显式声明可变：

```ocaml
let r = ref 0 in r := 5; !r      →  5
```

| 符号 | 作用 |
|---|---|
| `ref 0` | 造一个**可变的盒子** |
| `:=` | **赋值**——换掉盒子里的内容 |
| `!r` | **取值**——读出盒子里的东西 |

`r` 本身仍是不可变绑定（永远指向同一个盒子），变的是内容——类似 C 的 `int *const p`。
可变记录字段和数组用 `<-`。

**默认不可变，想要可变必须开口要**，跟 C/C# 正好相反。
`ref` 属于路线第 4 点（不可变性），今天只是让他知道它存在——真实 OCaml 代码里 `ref` 用得很少。
