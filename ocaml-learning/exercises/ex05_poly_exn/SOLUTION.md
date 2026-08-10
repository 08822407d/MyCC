# ex05_poly_exn 参考解

> ⚠️ **自己先试过再看。** 卡住了先跟 Claude 说卡在哪，读报错本身就是练习的一部分。
>
> 下面这份**实测 22 条全过**（2026-08-10，OCaml 5.5.0）。

## 第一部分：类型变量 `'a`

```ocaml
let swap (p : 'a * 'b) : 'b * 'a =
  let a, b = p in
  (b, a)

let rec repeat (x : 'a) (n : int) : 'a list =
  if n <= 0 then [] else x :: repeat x (n - 1)

let head_or (d : 'a) (lst : 'a list) : 'a =
  match lst with
  | [] -> d
  | x :: _ -> x
```

**TODO 1** 也可以写成 `(snd p, fst p)`。用 `let a, b = p in` 更常见，
因为它是**模式**（`let` 左边可以放模式，知识点 9.8 讲过），一眼看出在拆元组。

**TODO 2 的关键**：函数体里对 `x` **什么都没做**，只是原样 `::` 进表里。
这正是它的类型能保持 `'a` 的原因——**碰一下就塌了**。

**TODO 3 的关键**：`d` 和 `x` 必须同类型，否则两条分支的返回类型对不上，
`match` 的「各分支类型必须一致」直接拦下。**签名里两个 `'a` 同名就是这个意思。**

## 第二部分：异常

```ocaml
let safe_div (a : int) (b : int) : int =
  try a / b with Division_by_zero -> 0

let to_int_or (d : int) (s : string) : int =
  try int_of_string s with Failure _ -> d

let nth_or (d : 'a) (lst : 'a list) (n : int) : 'a =
  try List.nth lst n with
  | Failure _ -> d
  | Invalid_argument _ -> d

let classify (f : unit -> int) : string =
  try "ok:" ^ string_of_int (f ()) with
  | Division_by_zero -> "除零"
  | Failure msg -> "失败:" ^ msg
  | Not_found -> "没找到"
  | _ -> "其他"
```

**TODO 6 的两条分支内容一样**，能不能合并？可以：

```ocaml
try List.nth lst n with Failure _ | Invalid_argument _ -> d
```

这叫**或模式（or-pattern）**，用 `|` 把多个模式并成一条分支。
**它排在路线的 D1，这题不要求**——分开写两条完全正确。

**TODO 7 最容易错的地方**是 `try` 后面：

```ocaml
try f () with ...                          (* ❌ f () 是 int，其他分支是 string *)
try "ok:" ^ string_of_int (f ()) with ...  (* ✅ 全都是 string *)
```

报错会是 `This expression has type int but an expression was expected of type string`。
**根源是 `try … with` 是个表达式，所有分支必须同类型**——和 `if`、`match` 同一条规则。

**兜底 `| _ ->` 放最后**。挪到前面会触发 `Warning 11 [redundant-case]`，
而且这个项目故意关掉了 `-warn-error`，**它不会拦住你，得自己看警告**。
