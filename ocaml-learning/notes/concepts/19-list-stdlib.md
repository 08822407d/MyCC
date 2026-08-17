# 19. `List` 模块常用函数速查

> 2026-08-16 讲的。**起因是用户自己说的**：
>
> > 「说到这里我发现我又想不起来 `list` 的几个常用成员函数的用法了，需要巩固一下。」
>
> **所以这一篇是「查询表 + 立刻配练习」，不是讲解。**
> 光给表留不住 —— 这是 2026-08-06 复习轮就验证过的结论。
> 配套练习：[`ex08_list_stdlib`](../../exercises/ex08_list_stdlib/)（8 题 16 条）。

## 19.1 按「你想干什么」分组（全部实测）

| 想干什么 | 用哪个 | 备注 |
|---|---|---|
| 算长度 / 翻转 / 拼接 | `length` `rev` `append`(=`@`) `concat` | `concat [[1;2];[3]]` → `[1;2;3]` |
| **对每个元素做副作用** | **`iter`** | `('a -> unit) -> 'a list -> unit`，**返回 unit** |
| 变换每个元素 | `map` / **`mapi`**（带下标，从 0 起） | `mapi (fun i x -> i,x) ["a";"b"]` → `[(0,"a");(1,"b")]` |
| 挑一部分 | `filter` | 类型不变，长度变短 |
| 收拢成一个值 | `fold_left` / `fold_right` | |
| 问「**有没有**」 | **`exists`** | 空表 → **false** |
| 问「**是不是全都**」 | **`for_all`** | 空表 → **true**（空真） |
| 问「**含不含这个值**」 | **`mem`** | 直接给值不写谓词；用 `=` 比较（`memq` 才用 `==`） |
| 找第一个满足的 | **`find`** | ⚠️ **找不到抛 `Not_found`** |
| 一刀两断 | **`partition`** | `partition (fun x->x>2) [1;2;3;4]` → `([3;4],[1;2])`，**返回元组** |
| 排序 | **`sort`** | 要 comparator，**就是 C 的 `qsort`** |
| 切前/后 n 个 | `take` / `drop` | `take 2 [1;2;3;4]` → `[1;2]` |

## 19.2 ⭐ 排序：回收 C1 的 `qsort`

```ocaml
List.sort compare [3;1;2]                     →  [1; 2; 3]     升序
List.sort (fun a b -> compare b a) [3;1;2]    →  [3; 2; 1]     降序
```

**和 `qsort(a, n, sz, cmp)` 一模一样**——换 comparator 就换顺序。
`compare` 是多态比较，返回 `-1/0/1`，**和 C 里 `return *a - *b` 同一套约定**。

## 19.3 ⚠️ 两组容易拿反的

### `exists` vs `for_all` —— 空表上结果相反

| | 空表时 | 为什么 |
|---|---|---|
| `exists` | **false** | 找不到任何满足的 |
| `for_all` | **true** | 找不到任何反例 |

**不是特例，是「有一个」和「全都」的定义使然。** 数学上叫**空真（vacuous truth）**。

### `iter` vs `fold` / `map` —— 判据是「要不要收集结果」

```ocaml
let acc = ref 0 in List.iter (fun x -> acc := !acc + x) lst; !acc   (* 靠副作用 *)
List.fold_left ( + ) 0 lst                                          (* 靠返回值 *)
```

**`fold` 那版更好**（无可变状态）。**但 `iter` 不是没用**——真做副作用（打印、写文件）时
它才对，因为那时本来就不需要返回值。

## 19.4 ⭐⭐ comparator：`compare` 不是「升序」，以及 `( - )` 的溢出陷阱

> 2026-08-17 补。**起因是用户自己问的**：「OCaml 里只提供了默认升序的 `compare`
> 而没有降序的，是不是因为建议使用一层薄封装交换两个参数来达到这个目的？」
> 顺带收掉了**挂了三次才答的那道题**：`List.sort ( - ) [3;1;2]` 能用吗、有没有隐患。

### ① 措辞先纠正：`compare` 本身没有方向

```
compare : 'a -> 'a -> int
compare 1 5 → -1      compare 5 5 → 0      compare 5 1 → 1
```

**它只回答「a 相对 b 如何」，三个值。** 「升序」来自 `List.sort` 的约定
（文档原话：*positive if the first is greater, negative if the first is smaller*，
排出 *increasing order*）。**方向 = `compare` 说实话 + `sort` 规定「负数排前面」。**
→ **要降序就让 comparator 说反话。**

### ② 为什么标准库不给降序版

**降序只是无数派生顺序中的一个**（按 key、按长度、多级排序…）。标准库给的是
**一个组合子**（收 comparator 的 `sort`）+ **一个规范比较函数**（`compare`），其余自己拼。
**和 C 完全一样——libc 只给 `qsort`，不给 `qsort_desc`。** 他这个类比是对的。

### ③ 三种降序写法，都对但不等价

```
List.sort (fun a b -> compare b a) lst        ✅ 交换参数 —— 首选
List.rev (List.sort compare lst)              ⚠️ 多一趟 O(n)，相等元素相对顺序被翻转
List.sort (fun a b -> - (compare a b)) lst    ⚠️ 取负 —— 坏习惯，见 ④
```

**用户猜的「交换两个参数」正是首选**：一趟搞定、意图直白、不碰返回值的数值。

### ④ ⚠️⚠️ `( - )` 当 comparator：能用，但会溢出（**实测**）

```
List.sort ( - ) [3;1;2]                 →  [1;2;3]              小数字上没问题

compare   max_int min_int               →   1      ✅ 说实话
( - )     max_int min_int               →  -1      ❌ 回绕成负数，说反话

List.sort compare [min_int; max_int]    →  [min_int; max_int]   ✅
List.sort ( - )   [min_int; max_int]    →  [max_int; min_int]   ❌ 排反了
```

根因：`max_int - min_int` 真值是 `2^63-1`，装不进 63 位 int（`Sys.int_size = 63`）。

**这就是 C 里 `return *a - *b` 的经典毛病**，而且 **C 比 OCaml 更糟**：

| | 溢出时 |
|---|---|
| **OCaml** | **回绕**，行为确定、可复现。结果错但不失控 |
| **C** | **有符号溢出是 UB**，编译器可假设它不发生 → `-O2` / `-O0` 可能表现不同 |

**更坏的后果**：comparator 说反话会破坏**传递性**，而排序算法以它为前提 →
有些实现会读越界或死循环。**「comparator 必须一致」不是建议，是前提。**

**正确写法**：

| | |
|---|---|
| ❌ `( - )` / `a - b` | 溢出风险 |
| ✅ **`compare`** | 只返回 -1/0/1，**永不溢出** |
| ✅ C 里 | `return (*a > *b) - (*a < *b);` 或显式三分支 |

> **`compare` 安全恰恰因为它只返回三个值** —— 它不说「差多少」，只说「谁大」。
> **接他的编译器目标**：自己实现比较/排序、或生成比较代码时，
> **别把「差值」和「顺序」混为一谈。**

## 19.5 ⛔ 故意没讲的

- **所有 `_opt` 版本**（`find_opt` / `nth_opt` / `assoc_opt` …）——它们返回 `option`，
  **那块用户 2026-08-10 要求推迟了**。现在一律用会抛异常的版本 + `try … with`。
  → **`option` 重启之后要回来补这一节**，`find_opt` 比 `try List.find` 顺得多。
- `concat_map`、`filter_map`、`assoc`（关联列表）、`combine` / `split`、
  `sort_uniq`、`take_while` / `drop_while` —— 用到再说。

## 19.6 ⚠️ 接异常时别用 `_` 兜底

```ocaml
try List.find pred lst with Not_found -> "无"        ✅
try List.find pred lst with _ -> "无"                ❌ 会把谓词自己抛的异常也吞掉
```

**只接你预期的那个异常**——跟 C 里「别 catch 所有 signal」是同一条纪律。

## 相关

- [`15-map-filter.md`](15-map-filter.md) — `map` / `filter` 的原理和 `qsort` 切入点
- [`14-exceptions.md`](14-exceptions.md) — `Not_found` 和 `try … with`
- [`12-lists.md`](12-lists.md) — 列表本身的结构与代价（`@` 是 O(n)）
