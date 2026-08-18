# ex09_option — 把「可能没有」写进类型里

**要编辑的文件只有一个：[`main.ml`](main.ml)**，只改「你的代码」那一段。

> 前置：[`ex04_record_variant`](../ex04_record_variant/)（拆构造器）、
> [`ex05_poly_exn`](../ex05_poly_exn/) 和 [`ex08_list_stdlib`](../ex08_list_stdlib/)
> （**这题的 1/2/3 就是那两题的异常版重写**）。

## 起因：你自己写过的那行代码

ex08 第 8 题你写的是：

```ocaml
try List.find (fun s -> String.length s > 3) lst with Not_found -> "无"
```

代码是对的。但停下来看看它在干什么——**「找不到就给个默认值」是完全正常的情况**，
不是错误、不是意外，你却为它架了一整套**异常机制**。

C 里的同一个问题你天天绕：

```c
int n = atoi(s);        /* 返回 0 —— 是解析失败，还是字符串真的是 "0"？ */
```

```ocaml
int_of_string_opt "0"    →  Some 0     ← 成功，值就是 0
int_of_string_opt "abc"  →  None       ← 失败
```

**两者再也不会混。**

## 你只需要三样

```ocaml
Some x        (* 有值 *)
None          (* 没有 *)

match o with
| Some v -> ...
| None   -> ...
```

拆它的动作**你在 ex04 写过四遍**——和 `| Circle r ->` / `| Point ->` 一模一样，
只是构造器换了名字。**`option` 比 `shape` 还少一个构造器。**

⛔ **不用 `try` / `with`**，⛔ **不用自己定义类型**（那行带 `'a` 的 `type` 属于后面的 D1.5，
用它完全不需要知道）。

## 七道题，三组

| # | 函数 | 练什么 |
|---|---|---|
| 1 | `first_long` | **ex08 第 8 题的重写** —— `List.find_opt` |
| 2 | `to_int_or` | **ex05 的重写** —— `int_of_string_opt` |
| 3 | `nth_or` | **ex05 的重写** —— `List.nth_opt`（⚠️ 见题目里那条设计说明） |
| 4 | `describe` | 只消费，两支都要给出 string |
| 5 | `add_opts` | **同时看两个 option**（元组模式），而且要**自己造 `Some`** |
| 6 | `safe_div` | **生产 option**：把「没有结果」如实写进类型 |
| 7 | `head_opt` | 生产 option：对 `lst` 直接 match |

**1–3 是重头戏**：写完把它们和 ex05/ex08 的异常版并排看，**同一件事两种写法**。

**6、7 是转折**：前面都在**消费**别人给的 option，这两题要你**生产**一个。

## 怎么跑

```bash
bash ./scripts/ocaml.sh run ex09_option
```

或者直接跟 Claude 说「好了」/「跑一下」。
