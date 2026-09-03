# 16. `fold` —— 把一张表收拢成一个东西

> 2026-08-14 讲的（`win10-laptop`），**2026-08-17 复习并补写本篇**。
> 起因：用户说「`fold_left` 和 `fold_right` 我的印象也不是很深刻了，需要复习一下」。
>
> ⚠️ **这是 13–19 里唯一一篇迟了三天才补的**——当时讲完直接出了练习，忘了写笔记。
> 配套练习：[`ex07_fold`](../../exercises/ex07_fold/)（8 题 19 条，**已 19/19 全过**）。

## 16.1 ⭐ 有效的切入点（务必复用）

**不要从「fold 是高阶函数」讲起。从他自己写过的代码切进去**——
ex03 第 4 题他手写的尾递归求和：

```ocaml
let sum_tail (lst : int list) : int =
  let rec go (acc : int) (rest : int list) : int =
    match rest with [] -> acc | x :: tl -> go (acc + x) tl
  in
  go 0 lst
```

然后指出：**这段代码里只有两处和「求和」有关**——

```ocaml
    | x :: tl -> go (acc + x) tl        (* ① 怎么把新元素并进累加器 *)
    go 0 lst                            (* ② 累加器从哪开始 *)
```

其余（走一遍、到头返回 `acc`、递归）**对任何「边走边攒」的任务都长一个样**。

> **`fold` 就是把这两个旋钮做成参数，其余部分写好。**

再对齐 C 的累加循环，**两个旋钮位置一模一样**：

```c
int acc = 0;                       /* ← ② 起点 */
for (int i = 0; i < n; i++)
    acc = acc + arr[i];            /* ← ① 怎么并 */
return acc;
```

**效果**：路线里预判他会卡在 fold，**结果没卡**，还自己往前推了两步（见 16.5）。

## 16.2 签名与两个独立的洞

```ocaml
List.fold_left : ('acc -> 'a -> 'acc) -> 'acc -> 'a list -> 'acc
                  ^^^^^^^^^^^^^^^^^^^     ^^^^     ^^^^^^^    ^^^^
                  ① 怎么并               ② 起点    ③ 表      最终累加器
```

标准库连类型变量名都起好了。**关键：`'acc` 和 `'a` 是两个不同名的洞 → 可以毫不相干。**

| 元素类型 | 累加器类型 | 干的事 |
|---|---|---|
| `int` | `int` | 求和 / 计数 |
| `int` | **`int list`** | **反转列表**（`fun acc x -> x :: acc`） |
| `string` | `int` | 总长度 |
| `int` | **`bool`** | 判断是否全为正 |

**所以 `fold` 不只是「累加」，是「把一张表收拢成任意一个东西」。**

## 16.3 ⭐ 左右之分：让它自己画出来

**这个演示比任何解释都直观**（用字符串把括号打出来）：

```ocaml
List.fold_left  (fun acc x -> "(" ^ acc ^ "+" ^ x ^ ")") "0" ["1";"2";"3"]
→  "(((0+1)+2)+3)"

List.fold_right (fun x acc -> "(" ^ x ^ "+" ^ acc ^ ")") ["1";"2";"3"] "0"
→  "(1+(2+(3+0)))"
```

再用**减法**（不满足结合律）证明它们真的不同：

```ocaml
List.fold_left  (fun acc x -> acc - x) 0 [1;2;3]   →  ((0-1)-2)-3  =  -6
List.fold_right (fun x acc -> x - acc) [1;2;3] 0   →  1-(2-(3-0))  =   2
```

| | 起点在哪 | 怎么走 |
|---|---|---|
| `fold_left` | 最左 | 从左往右，**边走边算完**，结果层层套在外面 |
| `fold_right` | 最右 | 从右往左，**最外层要等里面全算完** |

### 为什么 `fold_right` 不是尾递归 —— 图里直接看得出

```
(1 + (2 + (3 + 0)))
 要算最外面那个 +，必须先有里面的结果
 → 必须先走到表尾，回来的路上才开始加
 → 中间每层的栈帧都得留着
```

而 `fold_left` 的 `(((0+1)+2)+3)` **最里面那层一上来就能算**，
算完换掉 `acc` 就往下走 —— 栈帧可复用。

**用户自己的说法是「后序遍历递归」**，一针见血（见 16.5）。

## 16.4 ⚠️ 参数顺序两处都反

```ocaml
List.fold_left  : ('acc -> 'a -> 'acc) -> 'acc    -> 'a list -> 'acc
List.fold_right : ('a -> 'acc -> 'acc) -> 'a list -> 'acc    -> 'acc
```

> **记法：累加器靠近它「来的那一侧」。**
> `fold_left` 累加器从左边来 → 写左边；`fold_right` 从右边来 → 写右边。函数参数同理。

### 实践判据

| 场景 | 用哪个 |
|---|---|
| 求和 / 计数 / 判断（结果与顺序无关） | **`fold_left`** ← **默认选它**，尾递归 |
| 要造保序的新表，表不长 | `fold_right` 一步到位，不用 `rev` |
| 同上但表可能很长 | **`fold_left` + `List.rev`** |
| `map`/`filter` 就能做的事 | **别用 fold**，用最窄的工具（意图更清楚） |

### 起点填什么：单位元

`sum` 填 `0`、`product` 填 `1`、`for_all` 填 `true` ——
**必须是该运算的单位元**，这样空表才得到正确答案，第一个元素并进来也不会被污染。

> 写编译器时会再遇到：常量折叠、归纳变量识别都要知道运算的单位元。

## 16.5 用户自己给出的两个准确概括（第八、第九个）

**① fold 的本质**（他主动往前推的）：

> 「fold 的真正意思是遍历列表元素，每一个迭代中执行传入的操作，
> 执行完毕后把 acc 的最终值返回出来。至于中间怎么操作，没有规定，随便写，
> 哪怕和 acc 完全无关也行。」

**基本准确，补一处**：那个「操作」的**返回值就是下一轮的 `acc`**。
用 C 说最清楚：**`fold` 的函数体对应 `acc = f(acc, x);` 这一整句，包括那个赋值**——
你写的表达式是等号右边，`acc =` 是 `fold` 替你写的。

所以下面两种「和 acc 无关」都合法：

```ocaml
fun _   x -> x           (* 无视 acc → 结果是最后一个元素 *)
fun acc _ -> acc + 1     (* 无视 x → 结果是元素个数 *)
```

**② 怎么才能不倒序**（问他之后他自己答的）：

> 「应该要有一个逆序遍历的 fold，不然就只能用后序遍历递归来实现了。」

**两条都对，而且正是 `fold_right` 的语义与实现两面**——
「逆序遍历」是语义，「后序遍历递归」是实现，**后者直接解释了它为什么不是尾递归**。

## 16.6 `map` / `filter` 都是 `fold` 的特例

```ocaml
let my_map f lst = List.rev (List.fold_left (fun acc x -> f x :: acc) [] lst)
let my_filter p lst =
  List.rev (List.fold_left (fun acc x -> if p x then x :: acc else acc) [] lst)
```

**`fold_left` + `::` 天然产出倒序**（`::` 只能往头部挂，而 `fold_left` 从左往右走，
**最后访问的元素挂在最前面**），所以要 `List.rev` 纠正回来。

> ⚠️ **但实际写代码时能用 `map`/`filter` 就别用 `fold`。**
> 不是性能问题，是**意图**：看到 `map` 就知道「一进一出、个数不变」，
> 看到 `fold` 得读完那个函数才明白。**用最窄的工具，是替读代码的人省事。**

## 相关

- [`10-recursion.md`](10-recursion.md) 的 10.6 — 尾递归；ex03 第 4 题的 `go` 就在那里
- [`15-map-filter.md`](15-map-filter.md) — `map` / `filter`，以及 `qsort` 切入点
- [`19-list-stdlib.md`](19-list-stdlib.md) — `List` 模块速查（`fold` 属于「收拢」那一类）

---

## 16.x fold 方向的最终确认（2026-09-03，用户主动核对）

**他的问题：**

> 「我再确认一下 List 和 Array 的 fold_left 和 fold_right 的方向，
> fold_left 是从头部或者说下标小的方向开始，而 fold_right 从下标大的方向开始？」

**答：两个都对，`List` 和 `Array` 行为一致。** 在 `f` 里加打印实测：

```
List.fold_left   f 的调用顺序: a b c
List.fold_right  f 的调用顺序: c b a
Array.fold_left  f 的调用顺序: a b c
Array.fold_right f 的调用顺序: c b a
```

### 🚩 但「开始」有个歧义，钉了一下

对 `fold_right` 来说**有两件事方向相反**：

| | 方向 |
|---|---|
| **走到那儿**（遍历链表 / 索引） | 头 → 尾（列表只能这么走） |
| **`f` 真正被调用** | **尾 → 头** ← 他问的是这个 |

```ocaml
let rec fold_right f l init =
  match l with
  | [] -> init
  | x :: rest -> f x (fold_right f rest init)
                    (*  ↑ 先把这一整坨算出来，才轮到外面这个 f *)
```

**必须先一路递归到底（头→尾），到底之后才开始往回调用 `f`（尾→头）。**

准确说法：**`fold_right` 的 `f` 是从尾端开始被调用的。**

### 括号图（比「顺序」更好记，沿用 16.x 那个演示）

```
List.fold_left  括号: (((0+a)+b)+c)
List.fold_right 括号: (a+(b+(c+0)))
```

**两边的起点 `0` 都在最里层**，区别只是它贴着哪一端。

### 四个签名（`List` / `Array` 形状相同）

```ocaml
List.fold_left  : ('acc -> 'a -> 'acc) -> 'acc -> 'a list -> 'acc
List.fold_right : ('a -> 'acc -> 'acc) -> 'a list -> 'acc -> 'acc
Array.fold_left  : ('acc -> 'a -> 'acc) -> 'acc -> 'a array -> 'acc
Array.fold_right : ('a -> 'acc -> 'acc) -> 'a array -> 'acc -> 'acc
```

记法仍然是：**累加器靠近它「来的那一侧」。**

⚠️ `Array` **没有带下标的 fold**；要下标用 `iteri` + `ref` 或 `for`。
