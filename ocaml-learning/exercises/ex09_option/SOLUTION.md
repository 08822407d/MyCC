# ex09_option 参考解

> ⚠️ **自己先试过再看。**
>
> 下面这份**实测 18 条全过**（2026-08-18，OCaml 5.5.0）。

## 第一部分：重写异常版

```ocaml
let first_long (lst : string list) : string =
  match List.find_opt (fun s -> String.length s > 3) lst with
  | Some s -> s
  | None -> "无"

let to_int_or (d : int) (s : string) : int =
  match int_of_string_opt s with
  | Some n -> n
  | None -> d

let nth_or (d : 'a) (lst : 'a list) (n : int) : 'a =
  match List.nth_opt lst n with
  | Some x -> x
  | None -> d
```

**和异常版并排看：**

| | 异常版（ex05 / ex08） | option 版 |
|---|---|---|
| `first_long` | `try List.find … with Not_found -> "无"` | `match List.find_opt … with Some s -> s \| None -> "无"` |
| `to_int_or` | `try int_of_string s with Failure _ -> d` | `match int_of_string_opt s with …` |
| `nth_or` | **两条** `with` 分支 | **一条** `None` |

**差别不在长短，在于**：异常版要求你**记住那个异常叫什么名字**
（`Not_found`？`Failure`？`Invalid_argument`？记错了就接不住，而且编译器不会提醒你）。
option 版**只有两种形状，穷尽性检查会盯着你**——漏了 `None` 直接 Warning 8。

## 第二部分：只消费

```ocaml
let describe (o : int option) : string =
  match o with
  | Some n -> "有:" ^ string_of_int n
  | None -> "没有"

let add_opts (a : int option) (b : int option) : int option =
  match (a, b) with
  | Some x, Some y -> Some (x + y)
  | _ -> None
```

**`add_opts` 的两个要点：**

1. **元组模式**一次匹配两个（知识点 9.8）。四种组合里只有一种要真干活，
   其余三种用 `_` 收掉。
2. **返回类型是 `int option`，所以要自己造一个 `Some`**——
   `Some (x + y)` 而不是 `x + y`。**括号不能省**（函数应用优先级最高，
   `Some x + y` 会被读成 `(Some x) + y`）。

也可以写成四条分支，正确但啰嗦：

```ocaml
| Some x, Some y -> Some (x + y)
| Some _, None -> None
| None, Some _ -> None
| None, None -> None
```

## 第三部分：生产 option

```ocaml
let safe_div (a : int) (b : int) : int option =
  if b = 0 then None else Some (a / b)

let head_opt (lst : 'a list) : 'a option =
  match lst with
  | [] -> None
  | x :: _ -> Some x
```

**对照 ex05 的同名函数，差别值得想清楚：**

| | ex05 版 | 这里 |
|---|---|---|
| `safe_div 10 0` | 返回 `0` —— **把失败伪装成了一个正常结果**，调用方分不出来 | `None` —— 如实说 |
| `head_or` / `head_opt` | 调用方**必须先想好**一个默认值 | 把「有没有」**交还给调用方决定** |

> **生产 option 的好处：你不替调用方做决定。** 有人想要默认值，有人想报错，
> 有人想跳过——返回 `option` 让他们各自决定；返回一个编造的默认值则把选择权吃掉了。

## ⚠️ `nth_opt` 为什么对负数下标还抛异常

```ocaml
List.nth_opt [10] 99    →  None
List.nth_opt [10] (-5)  →  Exception: Invalid_argument "List.nth"
```

**这是刻意的分工，不是不一致：**

| 情况 | 性质 | 用什么表达 |
|---|---|---|
| 表太短 | **正常**——调用方本来就该考虑「可能没有」 | **`option`** |
| 下标为负 | **调用方用错了**——负数下标根本没有意义 | **异常** |

> 这条判据以后会专门讲（`concepts/14` 的 14.7 一直给它留着位置）。
> 一句话版本：**「可能发生的正常情况」用 `option`，「不该发生的错误」用异常。**
