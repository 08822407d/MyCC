# ex06_map_filter 参考解

> ⚠️ **自己先试过再看。** 卡住了先跟 Claude 说卡在哪。
>
> 下面这份**实测 16 条全过**（2026-08-14，OCaml 5.5.0）。

## 第一部分：重写 ex03

```ocaml
let count_evens (lst : int list) : int =
  List.length (List.filter (fun x -> x mod 2 = 0) lst)

let double_all (lst : int list) : int list = List.map (fun x -> x * 2) lst
```

**对照你在 ex03 写的**：

```ocaml
let rec double_all (lst : int list) : int list =
  match lst with
  | [] -> []
  | x :: rest -> (x * 2) :: double_all rest
```

省掉的三样东西——**`match` 分支、基准情形、递归调用**——和「乘以 2」毫无关系，
它们对**任何**逐个变换都长一个样。`List.map` 把这部分写好了，只留一个洞给你。

`count_evens` 的思路变化更大：原来是「边走边累加」，现在拆成
**先挑（`filter`）→ 再数（`length`）** 两步。**两遍遍历换来一行代码。**

## 第二部分：`map` 会改类型

```ocaml
let to_strings (lst : int list) : string list = List.map string_of_int lst
let lengths (lst : string list) : int list = List.map String.length lst
```

⭐ **注意这两个都没写 `fun`** —— `string_of_int` 和 `String.length` 本来就是
`'a -> 'b` 形状的函数，**直接当参数传就行**。写成 `(fun x -> string_of_int x)`
不算错，但多了一层空转（和 ex02 那个 `sprintf "%s"` 是同类问题）。

## 第三部分：闭包

```ocaml
let keep_long (n : int) (lst : string list) : string list =
  List.filter (fun s -> String.length s > n) lst

let shift (k : int) (lst : int list) : int list = List.map (fun x -> x + k) lst
```

`n` 和 `k` 都是**外层参数**，传进去的函数直接就能用。

**这正是 C 的 `qsort` comparator 做不到的事**——裸函数指针带不了环境，
只能靠全局变量或 `qsort_r`。详见 `notes/side-topics/c-nested-functions-trampoline.md`。

## 第四部分：自己写高阶函数

```ocaml
let count_matching (pred : 'a -> bool) (lst : 'a list) : int =
  List.length (List.filter pred lst)
```

**注意 `pred` 是直接传给 `filter` 的**，不需要 `(fun x -> pred x)` 包一层。

也可以手写递归（同样正确，只是啰嗦）：

```ocaml
let rec count_matching pred lst =
  match lst with
  | [] -> 0
  | x :: rest -> (if pred x then 1 else 0) + count_matching pred rest
```

## 组合

```ocaml
let pos_doubled (lst : int list) : int list =
  List.map (fun x -> x * 2) (List.filter (fun x -> x > 0) lst)
```

### TODO 8 那个问题的答案

**先挑再变，还是先变再挑？这题上两种结果一样**，因为「乘以 2」不改变正负号
（`x > 0` 当且仅当 `2x > 0`）。

**但顺序一般是要紧的。** 反例：条件换成 `x > 3`——

```
[2; 5] --filter(>3)--> [5]    --map(*2)--> [10]
[2; 5] --map(*2)--> [4; 10] --filter(>3)--> [4; 10]     ← 不一样了
```

**判据：只有当变换不影响「条件成不成立」时，两个顺序才等价。**

性能上则**永远是先 `filter` 更好**——先筛掉的元素就不用变换了。

### 括号那一层看着有点乱

```ocaml
List.map (fun x -> x * 2) (List.filter (fun x -> x > 0) lst)
```

嵌套一深，**读的时候要从里往外**，和执行顺序反着。
路线里 **C3 的 `|>` 运算符**就是治这个的（≈ shell 管道），到时候会变成：

```ocaml
lst |> List.filter (fun x -> x > 0) |> List.map (fun x -> x * 2)
```

**这题先不用 `|>`**，先把嵌套写法写顺，回头才知道 `|>` 省了什么。
