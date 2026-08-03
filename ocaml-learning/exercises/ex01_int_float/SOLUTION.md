# ex01_int_float 参考答案

**自己写完之前别看。**

```ocaml
let double_int (n : int) : int = n * 2

let half_float (x : float) : float = x /. 2.0

let add_int_float (n : int) (x : float) : float = float_of_int n +. x
```

## 几个容易踩的点

- `x / 2.0` —— `/` 只接受 `int`，报 `This expression has type float but an
  expression was expected of type int`。
- `x /. 2` —— 反过来，`2` 是 `int`，浮点字面量要写 `2.0` 或 `2.`。
- `n +. x` —— `n` 是 `int`，不会自动变 `float`，必须 `float_of_int n`。
- 写成 `float n` 也对：`float` 是 `float_of_int` 的简写别名。
