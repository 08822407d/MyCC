# 练习的组织方式

这份约定的唯一目的：**用户只需要打开一个文件、写代码、说一声「好了」。**
建目录、写 dune、想怎么验证、跑构建、看输出——全是 Claude 的活。

## 用户视角的完整流程

1. Claude 说「新练习：`exercises/ex01_int_float/main.ml`」并附上题目要点
2. 用户打开那**一个**文件，只改「你的代码」那一段
3. 用户说「好了」/「跑一下」/「写完了」
4. Claude 自动构建运行，把自测结果贴回来，讲错在哪

用户不需要：建文件夹、删旧代码、改 dune、记命令、判断自己在哪台机器上。

## 目录结构

一道题一个目录，互不干扰。**永远不要让用户在旧练习上覆盖着写**——
新知识点就开新目录，旧的留着当参考。

```
exercises/
  dune-project          ← 整个 exercises 是一个 dune 工程
  dune                  ← 公共编译设置（关掉 warning-as-error）
  .ocamlformat
  ex00_smoke/           ← 冒烟测试，别删，交接自检要用
  ex01_int_float/
    README.md           ← 题目、提示、怎么读自测输出
    main.ml             ← ★ 用户唯一要编辑的文件
    dune                ← (executable (name main))
    SOLUTION.md         ← 参考答案 + 常见错法。用户写完之前别看
```

命名：`ex<两位序号>_<英文主题>`，序号跟教学顺序走，`list` 出来正好是有序的。

## `main.ml` 的固定骨架

三段式，顺序不能变——**用户的编辑区必须在最上面**，打开文件就看见。

```ocaml
(* ex01_int_float — 一句话说清这题练什么
   ------------------------------------------------------------------
   只改下面「你的代码」那一段。分隔线以下是自测，别动。
   题目和提示见同目录的 README.md。
   写完跟 Claude 说一声，它会自动构建运行并反馈。
   ------------------------------------------------------------------ *)

(* ======================= 你的代码（改这里） ======================= *)

(* TODO 1：... *)
let f (n : int) : int = failwith "TODO 1"

(* ===================== 分隔线以下别改 ===================== *)

let check name to_s expected thunk = ...
let () = ...
```

### 几条硬性要求

1. **函数签名写全类型标注**（`(n : int) : int`）。
   初学阶段这是脚手架：用户看得见期望的形状，编译器报错也更贴题。
   等类型推导讲熟了再逐步去掉。

2. **函数体一律是 `failwith "TODO n"`**，不是留空。
   这样未完成的练习**照样能编译**，跑起来会逐条报「还没做」，
   而不是甩一堆跟题目无关的语法错误。

3. **自测用 `check` + `thunk`，不要用 `assert`。**

   ```ocaml
   let check name to_s expected thunk =
     match thunk () with
     | actual ->
       if actual = expected then Printf.printf "  [OK] %s\n" name
       else Printf.printf "  [XX] %s -> 期望 %s，实际 %s\n" name (to_s expected) (to_s actual)
     | exception e ->
       Printf.printf "  [--] %s -> 还没做（%s）\n" name (Printexc.to_string e)
   ```

   `assert` 一炸就停，只能看到第一个错。`check` 把每条用例都跑完：

   ```
   [OK] 过了
   [XX] 结果不对（会把期望值和实际值都印出来）
   [--] 还没实现（failwith 还在）
   ```

   `to_s` 那个参数是为了能打印实际值——OCaml 没有通用的 `print_anything`，
   所以每条用例自己带一个转换函数（`string_of_int` / `string_of_float` / ...）。

4. **每个 TODO 至少两条用例**，其中一条走边界（负数、0、空列表之类）。

5. 自测区不引入用户还没学过的语法。`Printf.printf` 和 `match ... with exception`
   算是白名单——它们只出现在「别改」的区域，用户不用懂也能用。

## 谁负责建目录

Claude 直接写文件就行（`Write` 工具），四个文件一次写完。
`scripts/ocaml.sh new <名字>` 会生成同样结构的空骨架，手头没模板时可以用它起头。

## 跑的时候

```bash
bash ./scripts/ocaml.sh run ex01_int_float
```

两台机器同一条命令，脚本自己处理平台差异。

**注意用 `run <名字>` 而不是裸 `build`** —— `run` 只构建那一个练习目录，
别的练习写到一半也不会牵连。

## 关于 SOLUTION.md

- 写题的同时就写好，别等用户问。
- 除了答案，**还要列常见错法**（那才是有教学价值的部分）。
- 用户没自己动手之前，Claude 不要主动把答案贴进对话。
  用户卡住时先给方向、给报错的解读，实在要才给。
