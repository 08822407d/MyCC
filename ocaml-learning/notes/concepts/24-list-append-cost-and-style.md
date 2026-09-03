# 24. `@` 的代价方向、`concat_map`，以及「格式交给谁」

> **2026-09-01 讲。起因是 `ex10_type_and` 的 TODO 5，用户自己问出来的：**
>
> > 「我在 fold_left 中把遍历的当前元素拼到 acc 前面，这种写法有没有性能问题？
> > 因为我看到你的提示给出的是别的写法（虽然没有明着说），尤其是提到了 rev。
> > 然后就是整个练习中对写法风格有没有什么改进建议？」
>
> **答案：有，而且是平方级的。** 下面是完整讲解，可以脱离对话独立看。

---

## 24.1 规则：`@` 的代价是**左操作数**的长度

> **`a @ b`** —— 把 `a` **整个复制一遍**，让复制品的最后一个节点指向 `b`。
> **`b` 是共享的，一个字节都不拷。**

为什么必须这样？因为列表是**单向链表**，而且**不可变**：

```
a = [1; 2; 3]        1 → 2 → 3 → []
b = [4; 5]           4 → 5 → []

a @ b                1'→ 2'→ 3'→ 4 → 5 → []
                     └── 新造的三个节点 ──┘   └─ 原样共享 ─┘
```

要让 `3` 后面接上 `b`，就得有一个「指向 b 的 3」。但原来那个 `3` 是不可变的、而且可能被别人共享着，**不能就地改它的尾指针**——只能重新造一个。往前推，`2` 和 `1` 也都得重造。

**所以：`a @ b` 是 O(|a|)，和 `|b|` 完全无关。**

📌 这条在 [`12-lists.md`](12-lists.md) 里讲过（「`@` 是 O(n)」），
**这里补的是关键的下半句：O(n) 里的 n 指的是【左边那个】。**

---

## 24.2 他写的那行错在哪

```ocaml
and names_folder (f : folder) : string list =
  List.fold_left (fun acc e -> acc @ names_entry e) [] f.items
(*                             ^^^ 越来越长的那个在左边 *)
```

`acc` 每一轮都变长，而每一轮又要把它**完整复制一遍**：

| 轮次 | acc 长度 | 这一轮复制多少 |
|---|---|---|
| 1 | 0 | 0 |
| 2 | 1 | 1 |
| 3 | 2 | 2 |
| … | … | … |
| n | n−1 | n−1 |

总计 `0+1+2+…+(n-1)` = **O(n²)**。

### 实测（同一棵平铺的树，四种写法）

```
平铺 2000 个文件:
  acc @ 新的  (原写法)          6.3 ms
  新的 @ acc  (fold_right)      0.1 ms
  rev_append + rev              0.0 ms
  List.concat_map               0.0 ms

平铺 8000 个文件:
  acc @ 新的  (原写法)        169.3 ms
  新的 @ acc  (fold_right)      0.4 ms
  rev_append + rev              0.3 ms
  List.concat_map               0.1 ms

平铺 32000 个文件:
  acc @ 新的  (原写法)       9376.2 ms      ← 9.4 秒
  新的 @ acc  (fold_right)      3.3 ms
  rev_append + rev              1.4 ms
  List.concat_map               1.6 ms
```

**规模 ×4，时间 ×55。** 这就是 O(n²) 的形状。其余三种是 ×4 到 ×8，线性。

⚠️ 在 ex10 那棵 4 个文件的树上**根本看不出来**——
这是典型的「小数据永远发现不了、上线才炸」的写法。

---

## 24.3 三种正确写法

### ① 反过来：`fold_right` + 短的在左

```ocaml
List.fold_right (fun e acc -> names_entry e @ acc) f.items []
(*                            ^^^^^^^^^^^^^ 短的在左边 *)
```

对一个 `File` 来说 `names_entry e` 只有 1 个元素，复制 1 个；`acc` 直接共享。总代价线性。

> **记法：`@` 要把短的放左边。**
> 而 `fold_left` 天然让累加器在左、`fold_right` 天然让新元素在左
> —— **所以「想用 `@` 拼表」时通常该选 `fold_right`。**

### ② 老路：`::` 攒倒序 + `List.rev`

`::` 是 O(1)（只造一个节点），`List.rev` 是一遍 O(n)。这就是 ex07 学过的套路。
一小段一小段拼的时候用 `List.rev_append`：

```ocaml
List.rev (List.fold_left (fun acc e -> List.rev_append (names_entry e) acc) [] f.items)
```

### ③ **社区写法：一行 `List.concat_map`**

```ocaml
and names_folder (f : folder) : string list =
  List.concat_map names_entry f.items
```

> **`List.concat_map : ('a -> 'b list) -> 'a list -> 'b list`**
> 对每个元素调用一个「返回列表」的函数，再把所有结果接成一张表。
> 相当于 `List.concat (List.map f l)`，但只走一遍。

**「对每个元素产出一小段，最后拼起来」这个模式就该用它**，不用手写 fold。
性能也在最快那一档（32000 个用 1.6 ms）。

---

## 24.4 澄清：`fold_right` 现在不容易爆栈了

他学过「`fold_right` 不是尾递归」（[`16-fold.md`](16-fold.md)）。**这条在原理上仍然成立**，
但在**现在的 OCaml 上不再是首要顾虑**。100 万个元素实测：

```
  fold_right + @         成功，长度 1000000
  List.concat_map        成功，长度 1000000
  rev_append + rev       成功，长度 1000000
```

**三个都没爆栈。** OCaml 5 的栈是可增长的（甚至手写的非尾递归 `my_len` 跑 100 万也没事）。

→ **真正该顾虑的是 `@` 的方向，不是 `fold_right` 的栈。**

---

## 24.5 写法风格：分成两类，处理方式完全不同

### A 类：**格式** → 交给 ocamlformat，别自己纠结

`exercises/.ocamlformat` 已经配好（`profile = default`，`margin = 90`）：

```bash
bash ./scripts/ocaml.sh fmt
```

在他这份 ex10 代码上，格式化器会改这些：

| 他写的 | 改成 | 说明 |
|---|---|---|
| `1 + (List.fold_left …)` | `1 + List.fold_left …` | **括号多余** |
| `acc @ (names_entry e)` | `acc @ names_entry e` | **括号多余** |
| `[name]` | `[ name ]` | 列表字面量内侧留空格 |
| 行尾空格 | 清掉 | — |

> 🚩 **这回答了他很久以前问过的「加括号求稳会不会太谨慎」：**
> **放心加**，格式化器会把多余的删掉。它删了哪些，哪些就是多余的。
> 规律是：**函数应用（`f x`）的优先级比所有中缀运算符都高**，
> 所以 `f x + 1`、`a @ f x` 都不需要括号。

**唯一要他自己拿主意的一条**：格式化器会把短 `match` 折成一行——

```ocaml
match e with File (name, _) -> name | Folder f -> f.name
```

这是 `default` profile 的取舍，**不是对错**。多行写法（每分支一行）读起来更清楚。
想保住它，在 `exercises/.ocamlformat` 加一行（**已实测有效**）：

```
break-cases = all
```

✅ **2026-09-03 已加。** 他的原话：

> 「还是不要把短 match 压成一行了，**我自己写代码时不论多短的 `if…else` 都会清晰地分开
> 便于看清分支情况**。」

`exercises/.ocamlformat` 现在是 `profile = default` / `margin = 90` / **`break-cases = all`**。
实测生效：格式化后 `match` 保持每分支一行，只改无争议的地方（两处多余括号、`[ name ]`、行尾空格）。

### B 类：**语义 / 选型** → 格式化器管不了，得自己判断

ex10 里只有两条，都在 TODO 5：

1. **`@` 的方向**（24.2）
2. **该用 `List.concat_map` 而不是手写 fold**（24.3 ③）

**TODO 1–4 挑不出毛病。** 特别是 TODO 4 的 `1 +` 放在 fold 外面、
累加器命名成 `m`（比 `acc` 更点题），都是对的。

---

## 24.6 收口

| | 状态 | 建议 |
|---|---|---|
| ex10 TODO 1–4 | ✅ | 无 |
| ex10 TODO 5 | ~~`fold_left` + `acc @ …`~~ | ✅ **2026-09-03 他自己改成了 `List.concat_map`** |
| 格式 | 2 处多余括号、1 处行尾空格 | 跑 `bash ./scripts/ocaml.sh fmt` |

**一句话记住：**

> **`@` 的代价是左边那个的长度。往左边加是贵的，往右边加是免费的。**
> **「每个元素产出一小段再拼起来」= `List.concat_map`。**

---

## 教学备注

- 这一问**完全是他自己提的**，而且**同时问了性能和风格两件事**——
  说明他开始有「不只是能跑就行」的意识了。这是第一次。
- **有效的答法是给基准测试。** 光说 O(n²) 他会信但没感觉，
  给出「32000 个要 9.4 秒 vs 1.6 毫秒」之后不需要再解释。
- **「格式交给工具、选型自己判断」这个二分对他很受用**，
  因为它把「我该不该纠结这个」变成了一个有明确答案的问题。

---

## 24.7 后续（2026-09-03）

### 他说「concat_map 是啥，我没什么印象」

→ 09-01 那次是**顺口带过的**，没展开。**教训：新的库函数不能只在收口表里出现一次。**

重讲的路子（有效）：**先给他看 `map` 的结果差在哪**——

```ocaml
List.map names_entry demo.items      (* → string list list  ← 多了一层 *)
List.concat (List.map names_entry demo.items)   (* → string list *)
List.concat_map names_entry demo.items          (* 两步合一，只走一遍 *)
```

**「你要的是 `string list`，手上是 `string list list`，中间差一次拍平」** —— 这句让他一次就懂了，
比先讲签名有效得多。

再给三个形状（一对一 / 一对多 / 一对零）：

```ocaml
List.map        (fun x -> x * 2)     [1;2;3]   (* [2;4;6]        一对一 *)
List.concat_map (fun x -> [x; x])    [1;2;3]   (* [1;1;2;2;3;3]  一对多 *)
List.concat_map (fun x -> if x > 1 then [x] else []) [1;2;3]  (* [2;3] 一对零 = 能当 filter *)
```

| 每个元素产出 | 用 |
|---|---|
| 恰好 1 个 | `List.map` |
| 0 或 1 个 | `List.filter_map` |
| 任意个 | **`List.concat_map`** |

### 他改完之后剩的一处：η-展开

他写的是：

```ocaml
List.concat_map (fun e -> names_entry e) f.items
```

**功能对**，但那个 lambda 什么都没做。

> **η-展开（eta-expansion）** — `fun x -> f x` 和 `f` 是同一个函数。
> 反过来收成 `f` 叫 **η-收缩**，社区默认写收缩后的形式。

讲法：接他早学过的**「函数是值」**（知识点 4），
以及他自己问过的 `List.fold_left ( + ) lst`（那里他就是直接传函数、没套 lambda）。

**判据：如果 lambda 的函数体只是「把参数原样喂给另一个函数」，这个 lambda 是多余的。**

```ocaml
List.map (fun x -> string_of_int x) l   (* 多余 *)
List.map string_of_int l                (* ✅ *)
List.map (fun x -> x * 2) l             (* ✅ 不多余，函数体做了事 *)
```

⚠️ 对**已经有名字的函数**来说两种写法完全等价，没有性能或语义差别，纯可读性。
他一次就改对了。**ex10 最终 16/16。**
