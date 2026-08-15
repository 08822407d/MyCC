# ex06_map_filter — 用 `map` / `filter` 代替手写递归

**要编辑的文件只有一个：[`main.ml`](main.ml)**，只改「你的代码」那一段。

> 前置：[`ex03_list_recursion`](../ex03_list_recursion/)（手写递归版）、
> [`ex05_poly_exn`](../ex05_poly_exn/)（`'a` 多态）。
> 顺序见 [`../../notes/CURRICULUM.md`](../../notes/CURRICULUM.md) 阶段 C。

## 这题练什么

`map` / `filter` 是**两本教材共同指认的最大断层**。核心思路你已经很熟了——

```c
qsort(arr, n, sizeof(int), cmp);   /* 库负责「怎么走一遍」，你负责「每一步做什么」 */
```

**`map` 和 `filter` 就是列表版的这件事。**

## 八道题

| # | 函数 | 练什么 |
|---|---|---|
| 1 | `count_evens` | **重写 ex03 第 2 题**，注释里附了你当时的递归版 |
| 2 | `double_all` | **重写 ex03 第 3 题**，同上 |
| 3 | `to_strings` | `map` 的 `'a -> 'b`：**类型变了**（filter 做不到） |
| 4 | `lengths` | 同上，而且可以直接把库函数当参数传 |
| 5 | `keep_long` | **闭包**：判断函数里用到外层参数 `n` |
| 6 | `shift` | 同上 |
| 7 | `count_matching` | ⭐ **自己写一个高阶函数**（前六题都是在用别人的） |
| 8 | `pos_doubled` | `filter` 和 `map` 串起来 |

**1–2 是重头戏**：写完把两个版本并排看，`map`/`filter` 到底省掉了什么就一目了然了。

**大部分答案是一行**，所以这题没有 `match` 骨架。

## 只需要三个函数

```ocaml
List.map    : ('a -> 'b)   -> 'a list -> 'b list
List.filter : ('a -> bool) -> 'a list -> 'a list
List.length : 'a list -> int
```

⛔ **不用 `fold`**（还没讲，路线里它单独排一步）、**不用 `option`**、**不用自己定义类型**。

## 一张能救命的表

| | 元素个数 | 元素类型 |
|---|---|---|
| **`map`** | **不变**（一进一出） | **可变**（`'a` → `'b`） |
| **`filter`** | **可变**（可能变少） | **不变**（还是 `'a`） |

**这张表是从签名直接读出来的**：`map` 两个洞所以类型能变，`filter` 一个洞所以不能变。

## 顺带留意一件事

ex03 的**第 1 题（`sum_list`）和第 4 题（`sum_tail`）没有出现在这里**。

**不是漏了——`map` 和 `filter` 做不到求和。** 它们一个「逐个变换」、一个「逐个筛选」，
都没法把整张表**收拢成一个值**。那正是下一站 `fold` 的理由。

## 怎么跑

```bash
bash ./scripts/ocaml.sh run ex06_map_filter
```

或者直接跟 Claude 说「好了」/「跑一下」。
