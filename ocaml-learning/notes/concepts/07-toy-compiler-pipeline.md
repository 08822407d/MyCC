# 7. 玩具编译器的完整链路（`ignore` / `Unix` / 平台差异）

> 同样来自伯克利公开课的截图（2026-08-05 当晚第 4 张），课上给 `compile` 加了
> `compile_and_run`，把「源码 → 汇编 → 目标文件 → 可执行 → 跑起来抓输出」整条打通。
> **这一篇偏实用**，因为用户当晚明确说了「先不啃语言哲学，要学常见写法、能写点实用东西」。

课上的新代码：

```ocaml
let compile_and_run (program: string): string =
  compile_to_file program;
  ignore (Unix.system "nasm program.s -f macho64 -o program.o");
  ignore (Unix.system "gcc program.o runtime.o -o program");
  let inp = Unix.open_process_in "./program" in
  let r = input_line inp in
  close_in inp; r
```

---

## 7.1 `ignore` 是普通函数，不是关键字

```
$ eval 'ignore'
- : 'a -> unit = <fun>
```

把任何值变成 `()` 扔掉。**为什么这里非要它**：`Unix.system` 有返回值

```
$ eval 'Unix.system'
- : string -> Unix.process_status = <fun>
```

而**分号左边必须是 `unit`**（知识点 6.3 的 Warning 10）。`ignore (...)` 就是
「我知道它有返回值，我是故意扔的」。**社区标准写法，到处都是。**

## 7.2 ⚠️ 但这两行 `ignore` 掩盖了真实错误

`Unix.system` 返回的是**退出码**。`ignore` 掉 = **nasm / gcc 失败了也不知道**，继续往下跑。

**我当场真踩了一次**（改汇编时手滑导致链接失败）：

```
/bin/sh: 1: ./program: not found
Fatal error: exception End_of_file
```

真正的病根 `ld returned 1 exit status` 在上面被吞了，**报错点离病根隔了两步**。
对用户（C / 内核背景）的说法是：**这就是不检查 `system()` 的返回值**。这个类比他会秒懂。

课上这么写是图简单，不是最佳实践。

## 7.3 `Unix` 是**单独的库**，dune 里必须声明

OCaml 标准库很小，`Unix` 不在里面：

```
(executable
 (name main)
 (libraries unix))
```

不加就是 `Unbound module Unix`。**写任何碰系统的东西都会撞这条。**

（顶层里也一样，`eval` 要先 `#load "unix.cma";;`。）

## 7.4 `close_in inp; r` —— 最后那个 `r` 就是返回值

用上知识点 6.3：`e1; e2` 取 **e2** 的值。先关管道（unit，丢掉），整体的值是 `r`。
**这就是 `compile_and_run` 类型是 `string -> string` 的原因。**

整个函数的形状：写文件 → 汇编 → 链接 → 开管道跑 → 读一行 → 关管道 → 把那行还回去。
`string -> string` 读作「**喂一段源码，还你这程序的输出**」。这是课程写测试的钩子：

```ocaml
assert (compile_and_run "5000" = "5000")
```

用到的几个函数：

```
Unix.open_process_in : string -> in_channel      (对应 C 的 popen)
input_line           : in_channel -> string      (对应 fgets)
close_in             : in_channel -> unit        (对应 pclose)
```

## 7.5 ⚠️ `macho64` 是 macOS 的格式 —— 用户这台跑不了

**讲师在 Mac 上。** `ubuntu24-pc` 是 Ubuntu x86_64，必须改成 `elf64`：

```ocaml
ignore (Unix.system "nasm program.s -f elf64 -o program.o");
```

工具链实测都在：`/usr/bin/nasm`、`/usr/bin/gcc`、`/usr/bin/ld`，`uname -m` = `x86_64`。

## 7.6 `runtime.o` 是课程截图里没给的那一半

汇编里只有 `_entry` 没有 `main`，所以 `runtime.o` 必然是一段 C，
负责提供 `main`、调用 `_entry`、打印返回值。我按这个猜测补了一个，跑通了：

```c
#include <stdio.h>
extern long _entry(void);
int main(void) { printf("%ld\n", _entry()); return 0; }
```

**这解释了两件事**：

1. 为什么入口符号叫 `_entry` 不叫 `main` —— 把「用户程序」和「运行时」分开，
   这是编译器项目的标准结构，以后自己写编译器也会这么分。
2. 为什么 `compile_and_run` 能读到一行输出 —— **打印是 C 运行时干的，不是那四行汇编干的**。

---

## 7.7 在 `ubuntu24-pc` 上实测跑通的完整配方

**结果：**

```
compile_and_run "5000" => 5000
compile_and_run "1234" => 1234
```

**相对课上代码的三处改动**：`macho64` → `elf64`；dune 加 `(libraries unix)`；自己补 `runtime.c`。

`dune-project`：

```
(lang dune 3.20)
```

`dune`：

```
(executable
 (name main)
 (libraries unix))
```

`runtime.c`（先 `gcc -c runtime.c -o runtime.o` 编出来放在运行目录）：

```c
#include <stdio.h>
extern long _entry(void);
int main(void) { printf("%ld\n", _entry()); return 0; }
```

`main.ml`：

```ocaml
let compile (program : string) : string =
  String.concat "\n"
    [ "global _entry"
    ; "_entry:"
    ; Printf.sprintf "    mov rax, %s" program
    ; "    ret"
    ; "section .note.GNU-stack noalloc noexec nowrite progbits" ]

let compile_to_file (program : string) : unit =
  let file = open_out "program.s" in
  output_string file (compile program);
  close_out file

let compile_and_run (program : string) : string =
  compile_to_file program;
  ignore (Unix.system "nasm program.s -f elf64 -o program.o");
  ignore (Unix.system "gcc program.o runtime.o -o program");
  let inp = Unix.open_process_in "./program" in
  let r = input_line inp in
  close_in inp; r

let () =
  print_endline ("compile_and_run \"5000\" => " ^ compile_and_run "5000");
  print_endline ("compile_and_run \"1234\" => " ^ compile_and_run "1234")
```

### ⚠️ 那行 `section .note.GNU-stack …` 的坑（踩过两次，记住）

不加它，链接会警告：

```
/usr/bin/ld: warning: program.o: missing .note.GNU-stack section implies executable stack
```

只是警告，不影响跑。**但要加就必须加在汇编的最后一行** —— 放开头会把 `_entry`
塞进那个 section，直接链接失败：

```
`_entry' referenced in section `.text' of runtime.o:
    defined in discarded section `.note.GNU-stack' of program.o
```

（顺带：**上面 7.2 那次「报错点离病根两步」的现场，就是这么造出来的。**）

> 实测代码建在 scratchpad 里（session 级临时目录，**已经不在了**）。
> 本节的配方是完整的，照抄即可重建，不需要回去找。
