# ex04_record_variant 参考答案

> **自己写完之前别看。** 卡住了先跟 Claude 说卡在哪，比直接看答案有用。

全部实测通过（10 条期望值逐条核对过）。

## TODO 1 — `fabric_name`

```ocaml
let fabric_name (f : fabric) : string =
  match f with
  | Linen -> "亚麻"
  | Cotton -> "棉"
  | Wool -> "羊毛"
```

三个构造器都不带数据 → **只有①分辨形状，没有②取数据**，所以直接写结果。

## TODO 2 — `area`

```ocaml
let area (s : shape) : float =
  match s with
  | Point -> 0.
  | Circle r -> 3.14 *. r *. r
  | Rect (w, h) -> w *. h
```

**常见错法**：写成 `3.14 * r * r` → 编译错误。**浮点是另一套运算符**（知识点 2）。

三条分支正好覆盖三种构造器：`Point` 带 0 个数据、`Circle` 带 1 个、`Rect` 带 2 个。

## TODO 3 — `kind`

```ocaml
let kind (s : shape) : string =
  match s with
  | Point -> "点"
  | Circle _ -> "圆"
  | Rect _ -> "矩形"
```

**和 TODO 2 对照着看**：同一个类型、同样三条分支，区别只在空位里填什么。

| | 空位填什么 | 后果 |
|---|---|---|
| TODO 2 | 名字 `r` / `(w, h)` | 右边能用这些名字 |
| TODO 3 | `_` | 右边用不到，也不会挨 unused 警告 |

⚠️ **空位不能整个省掉**：写 `| Circle -> "圆"` 会报
`The constructor Circle expects 1 argument(s), but is applied here to 0`。

## TODO 4 — `cost`

```ocaml
let cost (p : project) : int =
  let base = match p.itm with Shirt -> 100 | Pants -> 150 | Hat -> 60 in
  let factor = match p.fab with Linen -> 1.5 | Cotton -> 1.0 | Wool -> 2.0 in
  int_of_float (float_of_int base *. factor)
```

**两个考点：**

1. **`p.itm` / `p.fab` 取记录字段**，和 C 的 `p.itm` 一样。
2. **最后一行的类型转换**：`base` 是 `int`，`factor` 是 `float`，
   **OCaml 不会替你提升**（知识点 5）。必须显式 `float_of_int`，算完再 `int_of_float`。

对一下期望值：`100 × 1.0 = 100`、`150 × 2.0 = 300`、`60 × 1.5 = 90`，三个都是整数，
所以 `int_of_float` 怎么取整都不影响（**但换成别的数就要小心，它是朝零截断**）。

## TODO 5 — `rewrap`

```ocaml
let rewrap (p : project) (new_fab : fabric) : project = { p with fab = new_fab }
```

**也可以写全**：

```ocaml
let rewrap p new_fab = { itm = p.itm; fab = new_fab }
```

两种都对、结果一样，但字段一多 `with` 就明显省事——**而且加字段时不用回来改**。

**为什么原件不会被改**：记录默认不可变，`{ p with … }` 是**在运行时造一个新记录**，
`p` 从头到尾没被碰过。最后那条测试就是验这个。

> 这个 `with` 和 **C# 9 `record` 的 `with` 表达式**是同一个东西，连关键字都一样。

## 全做完之后

下一步是 **阶段 B：`'a` 多态 → `option` → 异常**，
见 [`../../notes/CURRICULUM.md`](../../notes/CURRICULUM.md)。
