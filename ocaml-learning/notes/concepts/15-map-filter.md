# 15. 高阶函数（一）：`map` / `filter`

> 2026-08-11 讲的，对应 [`../CURRICULUM.md`](../CURRICULUM.md) 的 **C1**。
>
> **背景**：`map` / `filter` / `fold` 是两本教材同时指认的最大断层——
> CS 3110 单列一章，**ocaml.org 官方干脆放进「Lists」那一篇**（即学完列表就该会）。
>
> ⚠️ **`fold` 不在本篇**，它是 C2，**单独一步、单独练习**（预判用户会卡在那里）。

## 15.1 ⭐ 切入点：C 的 `qsort` comparator（**有效，务必复用**）

**不要从「函数式编程」讲起，从他天天用的 `qsort` 讲起。**

```c
static int asc (const void *a, const void *b) { return *(int*)a - *(int*)b; }
static int desc(const void *a, const void *b) { return *(int*)b - *(int*)a; }

int a[] = {3,1,4,1,5}, b[] = {3,1,4,1,5};
qsort(a, 5, sizeof(int), asc);    /* 同一个 qsort */
qsort(b, 5, sizeof(int), desc);   /* 只换了最后一个参数 */
```

实测输出：

```
升序 1 1 3 4 5
降序 5 4 3 1 1
```

> **`qsort` 自己不知道怎么比较——「怎么比较」是当参数传进去的。**

> **高阶函数（higher-order function）** — 把函数当参数收（或当返回值给）的函数。

**他早就会用了**，只是 C 里得靠函数指针，写起来啰嗦。**OCaml 只是让这件事变便宜了。**

## 15.2 `List.map`：把「对每个元素做什么」当参数传

```
- : ('a -> 'b) -> 'a list -> 'b list = <fun>
     └一个函数┘   └进的表┘   └出的表┘
```

实测：

```
List.map (fun x -> x * 2) [1; 2; 3]        →  [2; 4; 6]
List.map string_of_int [1; 2; 3]           →  ["1"; "2"; "3"]      (int list → string list)
List.map String.length ["a"; "bbb"; "cc"]  →  [1; 3; 2]            (string list → int list)
```

### ⭐ 回收：他已经手写过 `map` 了

ex03 的 TODO 3：

```ocaml
let rec double_all lst =
  match lst with
  | [] -> [] | x :: rest -> (x * 2) :: double_all rest
```

**这就是 `map` 把「乘以 2」写死之后的样子。** `List.map` 只是把那个行为**提出来当参数**
——和 `qsort` 把比较提出来是同一招。**这个回收很有效，因为那份代码是他自己写的。**

## 15.3 `List.filter`：把「留不留」当参数传

```
- : ('a -> bool) -> 'a list -> 'a list = <fun>
```

```
List.filter (fun x -> x mod 2 = 0) [1;2;3;4;5;6]                    →  [2; 4; 6]
List.filter (fun s -> String.length s > 2) ["a";"bbb";"cc";"dddd"]  →  ["bbb"; "dddd"]
```

> **谓词（predicate）** — 返回 `bool` 的函数，用来回答「是/否」。

## 15.4 ⭐⭐ 关键对比：**差别全写在洞的个数上**

```
List.map    : ('a -> 'b)   -> 'a list -> 'b list      ← 两个洞
List.filter : ('a -> bool) -> 'a list -> 'a list      ← 一个洞
```

| | 传进去的函数干什么 | 结果 |
|---|---|---|
| `map` | 把 `'a` **变成** `'b` | **长度不变**，类型可能变 |
| `filter` | 判断 `'a` **要不要** | **类型不变**，长度可能变 |

> **`filter` 只有一个 `'a`，因为它不加工元素、只是挑**——只可能变短，不可能变类型。
> **光读类型签名就能把两个函数的职责讲明白**，不用查文档。← 这是 B1（`'a`）的现金价值。

## 15.5 `map` 不在乎传进去的是不是谓词

用户答对的一题：`List.map (fun x -> x > 3) [1; 2; 3; 4; 5]`
→ `- : bool list = [false; false; false; true; true]`

**他的回答**：「是一个 bool 列表，表示原列表中对应位置的元素是否大于 3。」
**「对应位置」抓住了 `map` 最要紧的性质**：长度不变、位置一一对应。

**要点**：`map` 只管「拿每个元素喂给这个函数、把结果收集起来」，`'b` 这次恰好是 `bool` 而已。
**是 `filter` 才对「返回 bool」有要求**（它要拿那个 bool 做决定），而这写死在类型里。

## 15.6 组合：`count_evens` = 先筛后数

ex03 的 `count_evens` 他是把「筛」和「数」揉在一条递归里的。拆开是：

```
List.length (List.filter (fun x -> x mod 2 = 0) [1;2;3;4])   →   2
```

**先筛后数，两步各管一件事。** 原来那版一次遍历同时做完，**效率上更好**，
但读起来要看两眼才知道在干嘛。**这个权衡要跟他说清，别只说「高阶函数更好」。**

## 15.7 ⛔ 讲到哪了

**已讲**：15.1–15.6 全部。用户答对两题：
① 为什么 `'a` / `'b` 必须不同名（他说「**给了输出可以和输入不同类型的可能性**」——
**用词准确，而且这纠正了他 08-10 答错的那次**，当时他说「必须不是同一个类型」）；
② `List.map` 传谓词的结果类型。

**⬜ 挂着的（下次开工第一件事）**：我让他用 `map` / `filter` 各一行重写
`double_all` 和 `count_evens`，**他还没写**（当晚要睡觉了）。

```ocaml
let double_all lst  = ???
let count_evens lst = ???      (* ⚠️ 返回个数不是表，光 filter 不够，要再套一层 *)
```

**这两行是进 C2（`fold`）之前的确认动作**——按「讲过就要练」的规矩，先过手再进难的那步。

**还没讲**：`fold`（C2）、`|>`（C3）、`List` 模块其他常用函数（`iter` / `exists` /
`for_all` / `mem` / `sort` / `assoc` …）。

## 相关

- [`../CURRICULUM.md`](../CURRICULUM.md) — C1 / C2 / C3 / C4
- [`12-lists.md`](12-lists.md) — 列表本身；12.8 记着「高阶函数整块空白」，**本篇补掉了一半**
- [`13-polymorphism.md`](13-polymorphism.md) — `'a`，读懂这两个类型签名的前提
