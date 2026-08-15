# 14. 异常（基本用法）

> 2026-08-10 讲的，对应 [`../CURRICULUM.md`](../CURRICULUM.md) 的 **B3**。
> **这一篇是 2026-08-11 补写的** —— 当天没留概念笔记。
>
> **是用户主动选的这一块**（B2 `option` 被他要求推迟之后），而且要求**「不深入」**。
> 所以本篇只有「怎么用」，**故意不全**，见 14.7。

## 14.1 ⚠️ 锚点用 **C 的 `setjmp` / `longjmp`**，不要用 C# 的 `try-catch`

**他自述「C# 里也很少使用异常」**，所以 `try-catch` 对他不是锚点。
**用非局部跳转讲，效果好**：

```c
if (setjmp(buf) == 0) { ... longjmp(buf, 1); }   /* C：跳出多层调用栈 */
else { /* 收拾残局 */ }
```

> **异常 = 一个能穿透多层调用栈的非局部跳转，外加它自己带着的数据。**

## 14.2 抛和接

```ocaml
try 正常要算的东西 with
| 异常模式1 -> 出事时返回什么
| 异常模式2 -> ...
```

实测：

```
try 10/0 with Division_by_zero -> 0     →   0
```

- **抛**：`raise : exn -> 'a`，或者用现成的 `failwith : string -> 'a`
- **`failwith msg` 就是 `raise (Failure msg)` 的简写**

> ⭐ **`failwith` 的类型是 `string -> 'a`，`'a` 的原因是它永远不返回。**
> **这正是练习骨架里 `failwith "TODO"` 能放在任何位置都编译得过的原因**——
> 他在 ex04 那天就听懂了这一条。

## 14.3 ⭐⭐ 关键锚点：**`with` 后面就是 `match`，异常就是构造器**

这是本篇最有效的一条，因为它把异常直接接到他已经学透的 ADT 上。

```
$ eval 'Failure'
Error: The constructor Failure expects 1 argument(s), but is applied here to 0 argument(s)
```

**一模一样的报错他在 `Circle` 上见过。**

| 异常 | 对照 ADT |
|---|---|
| `Failure msg` | `Circle r` —— 带一个数据的构造器 |
| `Not_found` | `Point` —— 不带数据的构造器（实测 `- : exn = Not_found`） |
| `\| Failure _ -> …` | `\| Circle _ -> …` —— 空位填 `_` |
| `\| _ -> …` 兜底 | 同 `match` 的兜底，**必须放最后** |

所以 **`with` 后面那一串就是 `match` 分支**，规则原样适用：模式、空位、`_`、顺序。

### 和 C# 的关键区别

| | 怎么组织异常 | catch-all |
|---|---|---|
| C# | **继承树**（`Exception` 基类往下派生） | `catch (Exception e)` —— 抓**基类** |
| OCaml | **平的构造器**（都是 `exn` 这一个类型的构造器） | `\| _ ->` —— 用**通配符模式** |

> **OCaml 没有异常的继承层次。** `exn` 是一个**可扩展变体**，
> 所有异常都是它的构造器，彼此平级（实测 `exception My_err of int;; My_err 5` → `- : exn = My_err 5`）。

## 14.4 四个内置异常（练习里用到的）

| 异常 | 什么时候抛 | 实测 |
|---|---|---|
| `Division_by_zero` | 整数除以 0 | `10 / 0` |
| `Failure msg` | `failwith`、`int_of_string "abc"` | `Failure "int_of_string"` |
| `Invalid_argument msg` | 参数不合法 | `List.nth [1] (-5)` → `Invalid_argument "List.nth"` |
| `Not_found` | 查找失败 | `- : exn = Not_found` |

⚠️ **同一个函数可能抛不同的异常**，`List.nth` 就是活例子：

```
List.nth [1] 99     →  Failure "nth"                    (表太短)
List.nth [1] (-5)   →  Invalid_argument "List.nth"      (下标为负)
```

**ex05 TODO 6 专门考这个**，骨架给了两条分支。

## 14.5 ⚠️ `try` 的各分支类型必须一致

```
try 1 with _ -> "a"
Error: This constant has type string but an expression was expected of type int
```

**和 `match` / `if` 同一条规则**（知识点 9.8.2）：`try … with …` 是**表达式**，
整体要有一个确定的类型，所以正常分支和所有异常分支必须同类型。

**ex05 TODO 7 `classify` 就是考这个**：函数返回 `string`，
所以 `try` 后面那一段不能只写 `f ()`（那是 `int`），得转成 string。
—— **他第一版正是漏了 `"ok:" ^` 前缀**，其余四条异常分支全对，2026-08-11 补上后 22/22。

## 14.6 练习

[`ex05_poly_exn`](../../exercises/ex05_poly_exn/) 第二部分（TODO 4–7）：
`safe_div` / `to_int_or` / `nth_or` / `classify`。**2026-08-11 全过（22/22）。**

## 14.7 ⛔ 故意没讲的（**别以为讲过了**）

用户当时明确要求「不深入」，所以下面这些**一律没碰**：

- **自定义异常**（`exception My_err of int`）—— 本篇 14.3 只是拿它当证据演示了一下，**没教**
- **异常 vs `option` 的选型** —— 要等 B2 `option` 讲完才谈得上
- **资源清理**（`Fun.protect`，相当于 try/finally）—— 知识点 7.11 提过一句，仍未展开
- **异常的性能**、`raise_notrace`、backtrace
- `try ... with ... | exception` 在 `match` 里的写法（自测骨架里用了，**没讲**）

## 相关

- [`../CURRICULUM.md`](../CURRICULUM.md) — B3 / B2（`option` 推迟的原因）
- [`09-adt-and-pattern-matching.md`](09-adt-and-pattern-matching.md) — 构造器、模式、分支类型一致
- [`13-polymorphism.md`](13-polymorphism.md) — 同一次练习的另一半
