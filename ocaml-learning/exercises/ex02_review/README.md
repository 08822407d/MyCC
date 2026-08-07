# 综合复习：Printf / 类型转换 / 分号与 unit / ref

**要编辑的文件：只有 `main.ml`，而且只改「你的代码」那一段。**

**这道题没有新知识点**，全部是知识点 5、6、7、8 学过的东西。
出题的直接原因是 2026-08-06 那轮快问快答——三个洞全落在「听过但没动手过」的地方。

## 题目

把四个 `failwith` 换成真正的实现：

| | 函数 | 要求 | 考的是 |
|---|---|---|---|
| TODO 1 | `describe : string -> int -> string` | 拼成 `"age = 3"` 这样 | `Printf.sprintf` |
| TODO 2 | `avg_trunc : int -> int -> int` | 求平均并取整 | 类型转换双向 + 截断 |
| TODO 3 | `bump_twice : int ref -> int` | 加 1 两次，返回结果 | `ref` 三件套 + `;` |
| TODO 4 | `swap : int ref -> int ref -> unit` | 交换两个盒子的内容 | `ref` + `let … in` + `;` |

## 需要用到的（都学过，这里只是速查）

**Printf**

```ocaml
Printf.sprintf "..."   (* 返回 string *)
Printf.printf  "..."   (* 打到屏幕上，返回 unit *)
```

格式串里 `%s` 收字符串、`%d` 收整数。**格式串是编译期检查的**——写错了编译就过不去。

**类型转换**

```ocaml
float_of_int : int -> float
int_of_float : float -> int      (* ⚠️ 朝零截断，不是四舍五入、也不是向下取整 *)
```

浮点运算符是 `+. -. *. /.`，浮点字面量要写 `2.` 不能写 `2`。

**ref 三件套**

```ocaml
ref 0     (* 造一个盒子 *)
!r        (* 读盒子里的内容 *)
r := 5    (* 写盒子里的内容 *)
```

**分号**

`e1; e2` 表示「先算 e1，再算 e2，整体的值是 e2」。
⚠️ **`;` 左边必须是 `unit`**，否则会有 `Warning 10`。`r := 5` 正好是 `unit`。

## ⚠️ 两个故意埋的点

1. **`avg_trunc (-3) (-4)` 期望是 `-3` 不是 `-4`。**
   如果你算出 `-4`，说明把 `int_of_float` 当成向下取整了。它是**朝零截断**。
2. **TODO 4 返回 `unit`。** 别去 `return` 什么东西——它的全部工作就是副作用。

## 怎么验证

自己不用敲命令。写完在对话里说一声，Claude 会跑，然后把结果贴给你：

```
ex02_review 自测:
  [OK] describe "age" 3
  [XX] avg_trunc (-3) (-4) -> 期望 -3，实际 -4
  [--] swap 1 2 -> 还没做（Failure("TODO 4")）
```

- `[OK]` 过了
- `[XX]` 结果不对
- `[--]` 还没实现（`failwith` 没删）

**做一个跑一次也完全可以**，不必四个都写完再验。

## 卡住了

先别看 `SOLUTION.md`。把编译错误原样贴给 Claude——那个报错本身就是内容，
尤其是 `Warning 10` 和类型不匹配那两类。
