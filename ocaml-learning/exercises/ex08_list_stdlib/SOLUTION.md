# ex08_list_stdlib 参考答案

> **自己写完之前别看。** 卡住了先说卡在哪，比直接看答案有用。

16 条期望值逐条实测核对过。

```ocaml
let sum_via_iter (lst : int list) : int =
  let acc = ref 0 in
  List.iter (fun x -> acc := !acc + x) lst;
  !acc

let has_negative lst  = List.exists (fun x -> x < 0) lst
let all_positive lst  = List.for_all (fun x -> x > 0) lst
let contains_hello lst = List.mem "hello" lst
let sort_desc lst     = List.sort (fun a b -> compare b a) lst
let split_evens lst   = List.partition (fun x -> x mod 2 = 0) lst
let numbered lst      = List.mapi (fun i s -> string_of_int i ^ ":" ^ s) lst

let first_long lst =
  try List.find (fun s -> String.length s > 3) lst with Not_found -> "无"
```

## 逐题要点

**TODO 1 `iter` vs `fold`。** 同一件事两种写法：

```ocaml
let acc = ref 0 in List.iter (fun x -> acc := !acc + x) lst; !acc   (* iter：靠副作用 *)
List.fold_left ( + ) 0 lst                                          (* fold：靠返回值 *)
```

**`fold` 那版更好**——没有可变状态。**但 `iter` 不是没用**：真正要做副作用
（打印、写文件）时它才是对的，因为那时你本来就不需要返回值。
**判据：要不要收集结果。** 要 → `fold`/`map`；不要 → `iter`。

**TODO 2/3 `exists` vs `for_all`。**

| | 空表时 | 为什么 |
|---|---|---|
| `exists` | **false** | 找不到任何满足的 |
| `for_all` | **true** | 找不到任何反例 |

**空表上两个都"没东西可看"，结果却相反**——这不是特例，是「有一个」和「全都」的定义使然。
数学上叫**空真（vacuous truth）**。

**TODO 4 `mem` 不用谓词。** `List.mem "hello" lst` 直接给值。
⚠️ 它用 `=`（结构相等）比较，不是 `==`。（同族的 `memq` 才用物理相等。）

**TODO 5 comparator 就是 `qsort` 的第四参数。**

```ocaml
List.sort compare lst                    (* 升序 *)
List.sort (fun a b -> compare b a) lst   (* 降序 *)
```

也可以写 `(fun a b -> compare b a)` 之外的形式，只要返回 `-1/0/1` 的语义对就行——
**和 C 里 `return *a - *b` 是同一套约定**。

**TODO 6 `partition` 一次给两张表。** 写成两遍 `filter` 也对：

```ocaml
(List.filter p lst, List.filter (fun x -> not (p x)) lst)
```

但那样**遍历了两遍**，而且谓词写了两次（容易改一处漏一处）。`partition` 一遍搞定。

**TODO 7 `mapi` 的回调多收一个下标**，签名是 `(int -> 'a -> 'b)`，下标**从 0 开始**。

**TODO 8 `find` 抛 `Not_found`。**

```ocaml
try List.find pred lst with Not_found -> "无"
```

⚠️ **别用 `try ... with _ ->` 兜底**——那会把谓词自己抛的异常也吞掉。
**只接你预期的那个异常**，这跟 C 里「别 catch 所有 signal」是同一条纪律。

> 顺带：标准库其实有 `List.find_opt`，返回 `option`，比异常更常用。
> 等 `option` 那块重启之后，这题会有更顺的写法。

## 全做完之后

`List` 模块的常用面就过完了。还没碰的：`concat_map`、`filter_map`、
`assoc`（关联列表）、`combine` / `split`、以及所有 `_opt` 版本——用到再说。
