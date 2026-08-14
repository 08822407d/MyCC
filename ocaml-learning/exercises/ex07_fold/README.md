# ex07_fold — 用 `fold` 把一张表收拢成一个东西

**要编辑的文件只有一个：[`main.ml`](main.ml)**，只改「你的代码」那一段。

> 前置：[`ex03_list_recursion`](../ex03_list_recursion/)（你在那里手写过 `fold`，
> 就是第 4 题的 `go acc rest`）、[`ex06_map_filter`](../ex06_map_filter/)。
> 顺序见 [`../../notes/CURRICULUM.md`](../../notes/CURRICULUM.md) 阶段 C。

## 这题练什么

`fold` 是 `map` / `filter` / `fold` 三个里**最底层**的那个——路线里给它单独排了一步。

它就是你在 ex03 第 4 题手写的那个 `go`：

```ocaml
let rec go (acc : int) (rest : int list) : int =
  match rest with [] -> acc | x :: tl -> go (acc + x) tl
in
go 0 lst
```

里面只有**两处**和「求和」有关：`acc + x`（怎么并）和 `0`（起点）。
**`fold` 就是把这两个旋钮做成参数，其余部分写好。**

对应到 C 里就是那个再熟悉不过的累加循环：

```c
int acc = 0;                    /* ← 起点 */
for (int i = 0; i < n; i++)
    acc = acc + arr[i];         /* ← 怎么并 */
return acc;
```

## 八道题

| # | 函数 | 练什么 |
|---|---|---|
| 1 | `sum_list` | **补上 ex06 故意留的空缺**（map/filter 做不到收拢） |
| 2 | `product` | 起点换成 1 —— 想想为什么 |
| 3 | `count_evens` | ex06 用 filter+length 走两遍，这次一遍走完 |
| 4 | `total_length` | **累加器 `int`，元素 `string`** —— 两个洞是独立的 |
| 5 | `all_positive` | **累加器是 `bool`** |
| 6 | `my_rev` | **累加器是一张表**；几乎白送，刚讲过 |
| 7 | `double_all` | 要保序 —— 两条路都行，见题目注释 |
| 8 | `max_or` | 累加器 = 「目前见过的最大值」，外加 `'a` 多态 |

**4、5 是关键**：它们让「累加器可以是任何类型」这件事变得具体。

## 只需要这三个

```ocaml
List.fold_left  : ('acc -> 'a -> 'acc) -> 'acc    -> 'a list -> 'acc
List.fold_right : ('a -> 'acc -> 'acc) -> 'a list -> 'acc    -> 'acc
List.rev        : 'a list -> 'a list
```

⚠️ **两处参数顺序都是反的。** 记法：**累加器靠近它「来的那一侧」**——
`fold_left` 从左边来所以写左边，`fold_right` 从右边来所以写右边；函数的两个参数同理。

⛔ **不要用 `map` / `filter`**（那是 ex06 的活）、不用 `option`、不用自己写 `let rec`。
第 6 题还额外禁止直接调 `List.rev`。

## 选哪个 fold

| 场景 | 用哪个 |
|---|---|
| 结果和顺序无关（求和、计数、判断） | **`fold_left`**（尾递归，长表安全） |
| 要保持顺序，表不长 | `fold_right` 更直观 |
| 要保持顺序，表可能很长 | **`fold_left` + `List.rev`** |

## 怎么跑

```bash
bash ./scripts/ocaml.sh run ex07_fold
```

或者直接跟 Claude 说「好了」/「跑一下」。
