# ex07_fold 参考解

> ⚠️ **自己先试过再看。** 卡住了先跟 Claude 说卡在哪。
>
> 下面这份**实测 19 条全过**（2026-08-14，OCaml 5.5.0）。

## 第一部分：数值累加器

```ocaml
let sum_list (lst : int list) : int = List.fold_left (fun acc x -> acc + x) 0 lst
let product (lst : int list) : int = List.fold_left (fun acc x -> acc * x) 1 lst

let count_evens (lst : int list) : int =
  List.fold_left (fun acc x -> if x mod 2 = 0 then acc + 1 else acc) 0 lst
```

**起点为什么是 `0` 和 `1`？** 因为它必须是那个运算的**单位元**——加上它不变、乘上它不变。
这样空表才能得到正确答案（`sum [] = 0`、`product [] = 1`），
而且第一个元素并进来时不会被起点污染。

> 这条在写编译器时会再遇到：常量折叠、循环归纳变量识别都要知道运算的单位元。

**`sum_list` 也可以直接写 `List.fold_left ( + ) 0 lst`**——`( + )` 是把运算符当普通函数用
（两边要留空格，否则 `(*` 会被当成注释开头）。不算错，但初学阶段写 `fun acc x -> acc + x`
更清楚谁是累加器。

## 第二部分：累加器的类型 ≠ 元素的类型

```ocaml
let total_length (lst : string list) : int =
  List.fold_left (fun acc s -> acc + String.length s) 0 lst

let all_positive (lst : int list) : bool =
  List.fold_left (fun acc x -> acc && x > 0) true lst
```

**`total_length`**：元素是 `string`，累加器是 `int`。签名里 `'acc` 和 `'a` 是两个**不同名的洞**，
所以它们可以毫不相干。

**`all_positive`**：起点必须是 `true`。理由和上面一样——`true` 是 `&&` 的单位元，
所以空表得到 `true`（「所有元素都满足」在空集上按惯例为真）。

⚠️ 这个写法**不会提前退出**：即使第一个元素就是负数，它照样把整张表走完。
标准库的 `List.for_all` 会短路。这不算错，只是要知道差别。

## 第三部分：累加器是一张表

```ocaml
let my_rev (lst : 'a list) : 'a list = List.fold_left (fun acc x -> x :: acc) [] lst
```

**`fold_left` + `::` 天然产出倒序**，所以这题反而是「什么都不用纠正」的那个。
原因：`::` 只能往头部挂，而 `fold_left` 从左往右走，**最后访问的元素挂在最前面**。

```ocaml
(* 两种写法都对 *)
let double_all lst = List.rev (List.fold_left (fun acc x -> (x * 2) :: acc) [] lst)
let double_all lst = List.fold_right (fun x acc -> (x * 2) :: acc) lst []
```

- **(a) `fold_left` + `rev`**：走两遍，但**全程尾递归**，长表不怕
- **(b) `fold_right`**：一遍走完、不用纠正，但**不是尾递归**（必须先递归到表尾才能开始合并）

**标准库的 `List.map` 内部就是在做这个权衡**，所以实际写代码时直接用 `map` 就好。

## 第四部分：综合

```ocaml
let max_or (d : 'a) (lst : 'a list) : 'a =
  List.fold_left (fun acc x -> if x > acc then x else acc) d lst
```

累加器就是「到目前为止见过的最大值」，起点是 `d`。

⚠️ **注意这不是「数学上的最大值」**：`max_or 0 [-3; -9]` 得到 `0`，不是 `-3`,
因为起点 `0` 参与了比较。题目就是这么要求的（空表要给 `d`），但**这是个真实的设计陷阱**——
「默认值」和「单位元」不是一回事。真要求最大值，得先处理空表再从第一个元素起步。

`>` 在 OCaml 里是 `'a -> 'a -> bool`（多态比较），所以 `max_or "" ["b"; "a"]` 也能用。
⚠️ 多态比较对函数会抛异常、对浮点 `nan` 行为古怪，**以后写正经代码要留意**。
