# 整数和浮点：两套运算符，没有隐式转换

**要编辑的文件：只有 `main.ml`，而且只改「你的代码」那一段。**

## 题目

在 `main.ml` 里把三个 `failwith` 换成真正的实现：

| | 函数 | 要求 |
|---|---|---|
| TODO 1 | `double_int : int -> int` | 返回 `n` 的两倍 |
| TODO 2 | `half_float : float -> float` | 返回 `x` 的一半 |
| TODO 3 | `add_int_float : int -> float -> float` | 把 `n` 转成浮点，再和 `x` 相加 |

## 你需要知道的（这次的新知识就这三行）

1. 整数用 `+  -  *  /`
2. 浮点用 `+.  -.  *.  /.` —— 后面多一个点，是**另一套运算符**
3. 两者之间**不会自动转换**，要显式调用：
   - `float_of_int : int -> float`
   - `int_of_float : float -> int`（截断，不是四舍五入）

第 3 条是这道题真正想让你撞一下的地方。C 里 `5 + 1.5` 会把 `5` 悄悄提升成 `double`，
OCaml 不干这事——它宁可编译不过。

## 怎么验证

自己不用敲命令。写完在对话里说一声，Claude 会跑，然后把结果贴给你：

```
ex01_int_float 自测:
  [OK] double_int 21
  [XX] half_float 5.0 -> 期望 2.5，实际 2.
  [--] add_int_float 3 0.5 -> 还没做（Failure("TODO 3")）
```

- `[OK]` 过了
- `[XX]` 结果不对
- `[--]` 还没实现（`failwith` 没删）

## 卡住了

先别看 `SOLUTION.md`。把编译错误原样贴给 Claude，那个报错本身就是这节课的内容。
