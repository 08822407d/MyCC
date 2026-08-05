# 6. 从伯克利公开课代码里带出来的一串知识点

> **来源不是我出的题，是用户从公开课截图带回来的**（2026-08-05，连续三张）。
> 所以这些点是**按代码里出现的顺序**讲的，不是按教学难度排的。
> 每一条都在项目里实测过。

课上那段代码演进了三步：

```ocaml
(* 第 1 版：无视输入，永远吐同一段汇编 *)
let compile (program: string): string =
  String.concat "\n" ["global _entry"; "_entry:"; "    mov rax, 5000"; "    ret"]

(* 第 2 版：真的把输入插进去了 *)
let compile (program: string): string =
  String.concat "\n"
    ["global _entry"; "_entry:"; Printf.sprintf "    mov rax, %s" program; "    ret"]

(* 第 3 版：写进文件 *)
let compile_to_file (program: string): unit =
  let file = open_out "program.s" in
  output_string file (compile program);
  close_out file
```

---

## 6.1 模块限定名 `String.concat`

`模块名.函数名`，类似 C 的命名空间前缀。`String` 是标准库模块。

```
val String.concat : string -> string list -> string
```

先吃分隔符，再吃字符串列表。**模块系统本身还没讲**，这里只是让他知道这个点号是干什么的。

## 6.2 列表字面量用**分号**，不是逗号

⚠️ **头号陷阱：写成逗号照样能编译，但意思完全变了。**

```
["a"; "b"; "c"]   →  string list = ["a"; "b"; "c"]          (3 个元素)
[1, 2, 3]         →  (int * int * int) list = [(1, 2, 3)]   (1 个元素，是个三元组!)
```

逗号在 OCaml 里是**造元组**用的。另外**尾随分号合法**：`[1; 2; 3;]` 仍是三个元素。

## 6.3 `;` 的两个身份（重要，容易混）

| 位置 | 身份 | 含义 |
|---|---|---|
| 在 `[ ]` 里 | 列表元素分隔符 | 见 6.2 |
| 在 `[ ]` 外 | **顺序执行** | `e1; e2` = 算 e1 丢掉值，再算 e2，整体取 e2 的值 |

```
$ eval 'print_string "A"; print_string "B"; 42'
AB- : int = 42
```

而且**分号左边必须是 `unit`**，否则警告：

```
$ eval 'let g () = 1 + 1 in g (); print_endline "done"'
Warning 10 [non-unit-statement]: this expression should have type unit.
```

（第三个身份 `;;` 是**顶层的结束符，不是语言的一部分** —— 2026-08-03 已打过预防针。）

## 6.4 `Printf.sprintf`：格式串是**编译期类型检查**的

`sprintf` 返回 string，`printf` 打到 stdout —— 命名和 C 一致。但类型行为完全不同：

```
$ eval 'Printf.sprintf "    mov rax, %s"'
- : string -> string = <fun>          ← %s 那个洞变成了类型的一部分
```

```
$ eval 'Printf.sprintf "mov rax, %s" 5000'
Error: The constant 5000 has type int but an expression was expected of type string
```

C 里 `printf("%s", 5)` 是运行时炸，OCaml 里**根本编译不过**。
代价：**格式串必须是字面量**，不能是运行时拼出来的 string。

顺带：`Printf.sprintf "..."` 部分应用之后是个普通函数 —— 又一个柯里化的实例。

## 6.5 类型注解是「断言 + 核对」，不是「指定」

**用户原话的提问：「`: type` 的写法是『指定该表达式的类型，而不是自动推断』吗？」
→ 差一个关键的字。推断照常在跑，注解只是多加一条约束。**

- 一致 → 通过
- 冲突 → 报错，**绝不会帮你转换**（呼应知识点 5「没有强制转换」）

**证据：把课上那段的两个注解全删掉，推出来的类型分毫不差**（`%s` 已经逼着
`program` 是 string，`String.concat` 已经逼着返回值是 string）：

```
$ eval 'let compile program = String.concat "\n" [...; Printf.sprintf "...%s" program; ...]'
val compile : string -> string = <fun>
```

**但有一种情况注解确实在「指定」—— 把本来更宽泛的类型收窄：**

```
let id x = x           →  val id : 'a -> 'a = <fun>
let id (x : int) = x   →  val id : int -> int = <fun>
```

仍然不是转换，只是从可选类型里挑死一个。（`'a` 是什么**没展开**，留给以后讲多态。）

## 6.6 参数注解的括号是**语法必需**的

**用户主动问的**：`let compile (program: string): string` 里那对括号是不是必须的。

必须。`(x : t)` 是一个整体 ——「**带类型约束的模式**」，OCaml 语法规定这种约束
**只能写在括号里**。函数参数本质上是模式，所以要注解参数就必须套括号。

不加括号的两种下场：

```
let f (x : int) = 5   →  val f : int -> int = <fun>    (注解落在参数上)
let f x : int = 5     →  val f : 'a -> int = <fun>     (注解落在返回值上!)
let f x: int: int = 5 →  Error: Syntax error
```

**只差一对括号，含义完全不同。** 所以 `let compile (program: string): string` 里
括号内的 `: string` 说参数，括号外的 `: string` 说返回值。

## 6.7 `unit`：不是 C 的 `void`

```
$ eval '()'
- : unit = ()
```

`unit` 是**真正的类型**，有**唯一一个真正的值** `()`。C 的 `void` 是「没有返回值」；
OCaml 里函数必须返回点什么，「没什么可返回」就返回 `()`。

因为它是个值，所以能进列表、当参数、被 `let` 绑定 —— 和 int 完全平级。

**看到 `-> unit` 基本等于「这个函数是来搞副作用的」。** `print_string : string -> unit`。
`compile` 是纯函数，`compile_to_file` 是本课第一个不纯的函数。

## 6.8 `(compile program)` 的括号也是必需的 —— 函数应用左结合

**呼应知识点 4。** 实测去掉括号：

```
output_string file compile program;
Error: The function output_string has type out_channel -> string -> unit
       It is applied to too many arguments
       Hint: Did you forget a ;?
```

因为会被解析成 `((output_string file) compile) program` —— 把 `compile` 这个**函数本身**
当成要写出去的字符串传了进去。括号在这里不是美化，是「先算成一个值再当参数」。

## 6.9 `let file = … in` 的 body 吃掉了下面**两行** —— 呼应知识点 3

```ocaml
let file = open_out "program.s" in
output_string file (compile program);      (* ← 都在 file 的作用域里 *)
close_out file                             (* ← 因为 body 贪婪吃到尽头 *)
```

`let … in` 的 body 贪婪，**优先级低于 `;`**，所以整个 `e1; e2` 都是 body。
body 要是只吃一行，最后那个 `file` 就找不到了。

## 6.10 澄清的误解：`program` 不是 argv

**用户猜测**：`program` 参数是不是对应命令行参数 / C 的 `argc + argv`？→ **不是。**

`program` 就是个普通函数参数（一个 `string`），跟命令行没有天生关系。
它装的应该是**被编译的源代码**。用户看到「命令行传不同值结果不同」，那是
**调用方**（课上的 driver）自己去读了命令行再喂进来的，`compile` 本身对此一无所知。

现阶段容易混，是因为这个玩具的「源程序」恰好就是 `5000` 这么个数字。

真正对应 argv 的是 **`Sys.argv : string array`**，`Sys.argv.(0)` 是程序名。
**没有单独的 argc** —— 数组自带长度，`Array.length Sys.argv` 就是。

## 6.11 提了但没展开的（别当讲过）

- **OCaml 没有 RAII / defer**：`open_out` 给的 `out_channel` 必须自己 `close_out`。
  课上那段有真实隐患：`output_string` 抛异常的话 `close_out` 执行不到，句柄泄漏。
  正解是 `Fun.protect`（相当于 try/finally）。**只提了一句，没讲。**
- `'a`（多态/类型变量）—— 在 6.5 里露了脸，明确说了留到以后。
- 模块系统 —— 只讲了 `Module.f` 这个点号怎么读。
- `Array` / `.(  )` 索引语法 —— 只在 6.10 顺带出现。

## 6.12 实测：整段是能跑通的

在 scratchpad 里建了 dune 工程跑完整版，确实生成了 `program.s`：

```
global _entry
_entry:
    mov rax, 5000
    ret
```

⚠️ **另外发现一个坑（值得记住）**：课上那份第 1 版代码 **在 dune 的 dev profile 下编译不过** ——

```
Error (warning 27 [unused-var-strict]): unused variable program.
```

因为第 1 版根本没用到 `program`。惯例是把名字写成 `_program` 表示「我知道，故意的」。
课上的项目应该是把警告调松了。
