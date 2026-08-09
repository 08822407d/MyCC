# ex03_list_recursion 参考答案

> **自己写完之前别看。** 卡住了先跟 Claude 说卡在哪，比直接看答案有用。

全部实测通过。

## TODO 1 — `sum_list`

```ocaml
let rec sum_list (lst : int list) : int =
  match lst with
  | [] -> 0
  | x :: rest -> x + sum_list rest
```

`[]` 返回 `0`，因为 `0` 是加法的单位元——「什么都没加」就是 0。

## TODO 2 — `count_evens`

```ocaml
let rec count_evens (lst : int list) : int =
  match lst with
  | [] -> 0
  | x :: rest -> (if x mod 2 = 0 then 1 else 0) + count_evens rest
```

**常见错法**：想用 `if … then 1 + count_evens rest else count_evens rest`——
也对，但重复写了递归调用。上面那种把判断收在一个小括号里更干净。

⚠️ `if` 那一坨**必须加括号**，否则 `+ count_evens rest` 会被吃进 `else` 分支里
（知识点 10.5 那个不对称：`if c then A else B; C` 里 `C` 不归 `else`）。

## TODO 3 — `double_all`

```ocaml
let rec double_all (lst : int list) : int list =
  match lst with
  | [] -> []
  | x :: rest -> (x * 2) :: double_all rest
```

**基准情形返回 `[]` 不是 `0`**——返回类型是 `int list`。

递归情形是这题的核心：**左边造头，右边接上「剩下那截处理完的结果」**。
和 `sum_list` 对比着看最清楚：

```
sum_list:     x       +  sum_list rest      (用 + 把数拼起来)
double_all:  (x * 2) ::  double_all rest    (用 :: 把表拼起来)
```

**形状完全一样，只是拼接的工具从 `+` 换成了 `::`。**

## TODO 4 — `sum_tail`

```ocaml
let sum_tail (lst : int list) : int =
  let rec go (acc : int) (rest : int list) : int =
    match rest with
    | [] -> acc                    (* ← 考点：交出 acc，不是 0 *)
    | x :: tl -> go (acc + x) tl   (* ← 最后一件事就是调用 go *)
  in
  go 0 lst
```

### 两个坑

1. **基准情形返回 `0`** → 结果恒等于 `0`。一路攒好的东西必须交出去。
   （10.6 里踩过一次。）
2. **递归情形写成 `x + go acc tl`** → 那就**不是尾递归**了，回来之后还要做加法。
   正确写法是把加法做在**调用之前**：`go (acc + x) tl`。

### 和 TODO 1 的对照

| | 答案在哪儿攒 | 基准情形返回 | 尾递归 |
|---|---|---|---|
| `sum_list` | **回来的路上**（`x + …`） | `0` | ❌ |
| `sum_tail` | **去的路上**（全在 `acc` 里） | **`acc`** | ✅ |

> **判据（10.6）**：递归调用回来之后还有没有活干。有 → 那一帧得留着 → 不是尾递归。

## 顺带一提

TODO 1 和 TODO 3 都不是尾递归，但**在实际代码里这样写完全没问题**——
标准库的 `List.map` 自己就不是尾递归。列表长到几百万才需要操心，
到那时候通常也该换数据结构了。
