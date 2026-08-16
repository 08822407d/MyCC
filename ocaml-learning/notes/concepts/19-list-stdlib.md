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

## 19.4 ⛔ 故意没讲的

- **所有 `_opt` 版本**（`find_opt` / `nth_opt` / `assoc_opt` …）——它们返回 `option`，
  **那块用户 2026-08-10 要求推迟了**。现在一律用会抛异常的版本 + `try … with`。
  → **`option` 重启之后要回来补这一节**，`find_opt` 比 `try List.find` 顺得多。
- `concat_map`、`filter_map`、`assoc`（关联列表）、`combine` / `split`、
  `sort_uniq`、`take_while` / `drop_while` —— 用到再说。

## 19.5 ⚠️ 接异常时别用 `_` 兜底

```ocaml
try List.find pred lst with Not_found -> "无"        ✅
try List.find pred lst with _ -> "无"                ❌ 会把谓词自己抛的异常也吞掉
```

**只接你预期的那个异常**——跟 C 里「别 catch 所有 signal」是同一条纪律。

## 相关

- [`15-map-filter.md`](15-map-filter.md) — `map` / `filter` 的原理和 `qsort` 切入点
- [`14-exceptions.md`](14-exceptions.md) — `Not_found` 和 `try … with`
- [`12-lists.md`](12-lists.md) — 列表本身的结构与代价（`@` 是 O(n)）
