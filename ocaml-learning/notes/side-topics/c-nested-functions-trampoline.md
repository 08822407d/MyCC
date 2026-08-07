# 旁支：C 的嵌套函数、trampoline（蹦床）与可执行栈

> **这不是 OCaml 知识点。** 2026-08-07 讲 OCaml **闭包**时，用户问「C 里嵌套函数会不会
> 屏蔽可见性」，实测之后一路挖到了可执行栈。用户明确要求单独存档，**后面还要再仔细研究**。
>
> **主线内容在 [`../concepts/10-recursion.md`](../concepts/10-recursion.md)（尾递归 + 闭包）。**

## 这份记录解决的三个问题

1. C 的嵌套函数**会不会**遮蔽外层同名变量、**能不能**看见外层变量？
2. 内核源码里常见的 **trampoline** 到底是什么？
3. **在 NX / W^X 已经普及的今天，怎么还会出现可执行的栈？**

## 环境（实测于 2026-08-07，`win10-laptop` 的 WSL2）

- `gcc (Ubuntu 15.2.0-16ubuntu1) 15.2.0`
- 目标：x86-64，SysV ABI
- 源码：[`code/nested_fn.c`](code/nested_fn.c)（对照组）、[`code/nested_ptr.c`](code/nested_ptr.c)（实验组）

复现命令都写在两个 `.c` 文件的头注释里，**不用回来翻这篇**。

---

## 0. 先回答问题 1：遮蔽和捕获，C 和 OCaml 一样

用 [`code/nested_fn.c`](code/nested_fn.c) 实测：

```
$ gcc -Wall -Wextra -Wshadow -o nested_fn nested_fn.c
nested_fn.c:6:29: warning: declaration of 'n' shadows a parameter [-Wshadow]

$ ./nested_fn
shadow  count_shadow(5)  = 5    ← 内层 n 遮蔽了外层 n
capture count_capture(3) = 9    ← 不同名时，内层看得见外层的 n（3+3+3）

$ readelf -lW nested_fn | grep GNU_STACK
  GNU_STACK  ...  RW            ← 栈【不】可执行
```

**结论：「作用域嵌套 + 内层遮蔽外层」是通用规则，C 的直觉可以直接搬到 OCaml。**

⚠️ 我 2026-08-07 当场说过「这处 C 直觉套不过来」，**实测后已纠正**——套得过来。

两个附注：

- `-Wshadow` **默认不开**。这是「嵌套函数看着乱」的原因之一：编译器默认不提醒。
- **嵌套函数是 GNU 扩展，不在 C 标准里。**

**注意这个对照组的栈是 `RW`。** 说明「捕获外层变量」本身**不需要**可执行栈。
真正的分水岭在下面。

---

## 1. 问题 2：trampoline 是个通用叫法，不是一种技术

> **trampoline（蹦床）** — 一小段代码，唯一作用是把控制流从 A 桥接到 B，中途补上一点上下文。

所以内核里同名的东西有好几种，**互不相干**：

| 内核里的 | 干什么 |
|---|---|
| `arch/x86/realmode/rm/trampoline_64.S` | AP（从核）上电时实模式 → 保护模式 → 长模式的引导代码 |
| ftrace trampoline | 为每个 tracer 动态生成调用序列，省掉通用入口的判断开销 |
| BPF trampoline | fentry/fexit 挂载点，对接内核 ABI 与 BPF ABI |
| kprobes optimized probe | 用 `jmp` 替换 `int3`，跳到生成的代码里 |

**共同点只有「小、生成出来的、只负责转接」。**
用户在内核里见到的多半是上面这几种，**和 GCC 嵌套函数的蹦床没有血缘关系**，只是撞名。

下面讲的是 **GCC 嵌套函数的那一种**。

---

## 2. 逐行走查：蹦床是怎么被逼出来的

源码 [`code/nested_ptr.c`](code/nested_ptr.c)，汇编取自 `gcc -O0` 的 `objdump -d --no-show-raw-insn`。

### ① 捕获：`n` 得先有个「家」

| C 源码 | 对应汇编（`add_n`） |
|---|---|
| `static int add_n(int n, int x)` | `mov %edi,-0x34(%rbp)` |
| | `mov %esi,-0x38(%rbp)` |
| `int adder(int v) { return v + n; }` | `mov -0x34(%rbp),%eax` |
| | `mov %eax,-0x30(%rbp)` |

前两条是普通的存参数。**关键是后两条**：`n` 已经在 `-0x34` 了，GCC 又把它**复制**到 `-0x30`。

因为 `adder` 用了 `n`，`n` 就不能只是「`add_n` 的局部变量」了，它得成为
**一块有固定地址、能被外人指着说「就在这儿」的内存**。`-0x30` 就是这个「家」。

> 这一步是纯粹的**捕获**。对照组 `count_capture` 到此为止就结束了 —— 所以它的栈是 `RW`。

### ② `adder` 本身：约定好从 `%r10` 取环境

| C 源码 | 对应汇编（独立函数 `adder.0`） |
|---|---|
| `int adder(int v)` | `mov %edi,-0x4(%rbp)` |
| `return v + n;` | `mov %r10,%rax` |
| | `mov (%rax),%edx` |
| | `mov -0x4(%rbp),%eax` |
| | `add %edx,%eax` |

`adder` 被编译成一个**真实存在的独立函数**，符号名 `adder.0`，就在 `.text` 里。

`v` 走正常参数寄存器 `%edi`。但 `n` 不是参数 —— 它靠 **`%r10`** 拿到：
`mov %r10,%rax` 取出环境指针，`mov (%rax),%edx` 解引用，得到的正是 ① 里存进 `-0x30` 的 `n`。

> **`%r10` 在 x86-64 SysV ABI 里叫 static chain register（静态链寄存器）**，就是干这个用的。
>
> **所以 `adder.0` 有一条不成文的调用约定：进来时 `%r10` 必须指向那个「家」。**

### ③ `apply`：它根本不知道有这条约定

| C 源码 | 对应汇编（`apply`） |
|---|---|
| `static int apply(int (*f)(int), int x)` | `mov %rdi,-0x8(%rbp)` |
| | `mov %esi,-0xc(%rbp)` |
| `return f(x);` | `mov -0x8(%rbp),%rdx` |
| | `mov %eax,%edi` |
| | `call *%rdx` |

**全程没有出现过 `%r10`。**

`apply` 拿到一个 `int (*)(int)` 就 `call *%rdx`。它凭什么知道要先设置 `%r10`？
—— 不知道，**而且类型 `int (*)(int)` 里也没有任何地方能写下这个信息**。

> **矛盾成立**：`adder.0` 要求 `%r10` 有值 ↔ `apply` 保证不碰 `%r10`。
> 而 `int (*)(int)` 只有 8 字节，塞不进第二样东西。**GCC 被逼到墙角。**

### ④ 解法：现场在栈上写一段机器码

| C 源码 | 对应汇编（`add_n`，接 ①） |
|---|---|
| `return apply(adder, x);` | `lea -0x30(%rbp),%rax` |
| ↑ 就是 `adder` 这半行 | `add $0x4,%rax` |
| | `lea -0x30(%rbp),%rdx` |
| | `movl $0xfa1e0ff3,(%rax)` |
| | `movw $0xbb49,0x4(%rax)` |
| | `lea -0x69(%rip),%rcx  # adder.0` |
| | `mov %rcx,0x6(%rax)` |
| | `movw $0xba49,0xe(%rax)` |
| | `mov %rdx,0x10(%rax)` |
| | `movl $0x90e3ff49,0x18(%rax)` |

前三条算地址：`%rax` = 蹦床起点（`-0x2c`，紧贴在 `n` 的家后面），`%rdx` = 静态链（`-0x30`）。

后面六条**全是往栈上写常量字节**，`movl`/`movw` 的立即数不是数据，**是机器码**。
把这 28 字节反汇编回来（实测方法见文末）：

```asm
endbr64                                ; ← 0xfa1e0ff3，CET 落地点
movabs $0x0000000000001189,%r11        ; ← 0xbb49 + mov %rcx,0x6(%rax) 填的 adder.0 地址
movabs $0x00007ffd........,%r10        ; ← 0xba49 + mov %rdx,0x10(%rax) 填的静态链
jmp    *%r11                           ; ← 0x90e3ff49（末尾 0x90 是 nop 补齐）
nop
```

**读一遍就明白**：*我不干活，我只负责把 `%r10` 设好，然后跳给真正的 `adder.0`。*

> **这就是蹦床。** 两条 `movabs` 的立即数，一个编译期就知道（`adder.0` 的地址），
> 另一个**只有运行时才知道**（栈帧位置）——
> **这正是它没法预先放进 `.text`、必须现造的根本原因。**

### ⑤ 传出去的不是 `adder`，是蹦床

| C 源码 | 对应汇编 |
|---|---|
| `return apply(adder, x);` | `lea -0x30(%rbp),%rax` |
| | `add $0x4,%rax` |
| | `mov %rax,%rdx` |
| `                ↑ x` | `mov -0x38(%rbp),%eax` |
| | `mov %eax,%esi` |
| `        ↑ adder` | `mov %rdx,%rdi` |
| | `call apply` |

`%esi` = `x`，没悬念。**`%rdi` 是重点**：它装的是 `-0x2c(%rbp)`，**一个栈地址**。

> 源码里写的是 `adder`，编译后传出去的**根本不是 `adder.0` 的地址**，
> 而是刚才那 28 字节临时代码的地址。
> 于是 `apply` 里那句 `call *%rdx` 变成了「**调用栈上的一段数据**」。

### 栈布局小结（`%rbp` 相对）

```
-0x38   x                ← 第二个参数
-0x34   n                ← 第一个参数（原件）
-0x30   n 的副本          ← ★ 静态链指向这里；adder.0 里 mov (%rax),%edx 读的就是它
-0x2c   蹦床 28 字节       ← ★ 现场写入的机器码；传给 apply 的「函数指针」就是这个地址
-0x10   （帧记账，与蹦床主线无关，未深究）
-0x08   stack canary
```

---

## 3. 问题 3：为什么现代还会有可执行的数据区

**先纠正一个常见印象：NX 从来不是全局强制的，它是 per-page 的。**
W^X 是约定和默认值，不是硬件铁律 —— 硬件只提供 `XD`/`PXN` 位，**谁来设是软件的事**。

Linux 上的完整链条：

```
汇编/编译单元里的 .note.GNU-stack 段
        ↓  ld 汇总：只要有一个 .o 要求可执行栈，整个程序就要
ELF 的 PT_GNU_STACK 程序头（RW 还是 RWE）
        ↓  execve 时 fs/binfmt_elf.c 读它
栈 VMA 上加不加 VM_EXEC
```

**所以 `RWE` 不是漏洞，是这个程序主动申请的。** 实测两端：

```
$ gcc -O0 -o nested_ptr nested_ptr.c
ld.bfd: warning: requires executable stack (because the .note.GNU-stack section is executable)

$ readelf -lW nested_ptr | grep GNU_STACK
  GNU_STACK  ...  RWE
```

### 四个要点

1. **粒度极粗。** 申请一次，**整个进程的栈全程可执行**，不只是那 28 字节。
   栈溢出从「要 ROP」退化回「注入 shellcode 就能跑」—— **把 90 年代的攻击面整个还回来**。
2. **链接器现在会吼。** 上面那条 warning，较新的 binutils 从静默升到了 warning，方向是往 error 走。
   **手写汇编忘写 `.note.GNU-stack` 会触发同一条**，是个经典坑。
3. **发行版 / MAC 会拦。** SELinux 有 `execstack` 权限；`allow_execstack` 关掉的话程序直接跑不起来。
4. **为什么还留着 → 兼容性。** `READ_IMPLIES_EXEC` personality（老 ELF 没有 `PT_GNU_STACK` 时的
   兼容行为）就是为了不砸掉上古二进制。

### 它正在被淘汰（GCC 14+，本机实测）

```
$ gcc -ftrampoline-impl=heap -o nested_heap nested_ptr.c    # 无 warning
$ readelf -lW nested_heap | grep GNU_STACK
  GNU_STACK  ...  RW           ← 栈不再可执行
$ ./nested_heap
add_n(10, 5) = 15             ← 结果不变
```

改成在堆上 `mmap` 一块 `PROT_EXEC` 的内存放蹦床。
**`adder.0` 和 `apply` 一个字节都不用改，只换蹦床的住处**，攻击面从「整条栈」缩到一块专用小页。
和 JIT 引擎的做法一致（JIT 也需要可执行的动态代码，但从不用可执行栈，都是 `mmap` + `mprotect`）。

### 界限对照表

| 改动 | 蹦床 | GNU_STACK |
|---|---|---|
| `return apply(adder, x);`（原样，取地址） | 有 | **RWE** |
| `return adder(x);`（直接调用） | **没有**，GCC 直接 `mov …,%r10; call adder.0` | RW |
| `gcc -ftrampoline-impl=heap` | 有，搬到 `mmap` 的可执行页 | RW |

**区别只在「调用它」还是「把它交出去」。**

### 内核里为什么根本用不了

内核栈**永远不可执行**，也没有 `PT_GNU_STACK` 这种协商机制 —— 蹦床写进栈里，一跳过去就 fault。
加上嵌套函数是 GNU 扩展、和 CFI / `objtool` / 各种 sanitizer 都打架。
**用户「从来没用过嵌套函数」这个习惯是对的。**

---

## 4. 绕回 OCaml：同一个问题的三种答案

C 被逼到写机器码，根本原因是**它坚持函数指针必须是一个裸地址**。

OCaml / C# 换了个前提：**函数值不是一个地址，而是「代码指针 + 捕获的环境」这么一个对象。**
调用方多解一次引用就行，**不需要任何可执行的动态内存**。

| 语言 | 闭包怎么实现 | 需要可执行数据区吗 | 外层返回后还能用吗 |
|---|---|---|---|
| C（GNU 嵌套函数） | 栈上的 trampoline（**仅取地址时**） | **要** | **不能，悬垂** |
| C# | 编译器生成隐藏类（display class），捕获变量搬进字段 | 不要 | 能 |
| OCaml | 堆上的闭包对象（代码指针 + 捕获值） | 不要 | 能 |

最后一列是本质差别：C 里外层函数一 `return`，捕获的东西就没了；
OCaml 的闭包可以**活得比创建它的作用域久** —— 这就是为什么函数能当返回值
（`let make_adder n = fun x -> x + n`）。

代价是 OCaml 的函数值不能直接当 C 的裸函数指针用，所以给 C 传回调时要专门包一层。

> **「闭包怎么实现」是编译器课程的标准章节**（closure conversion / lambda lifting）。
> 用户以后会亲手写一个 —— **上面三种答案他现在都见过实物了。**

---

## 5. 后续可研究的方向（用户说了还要再看）

- **反汇编那 28 字节**：把字节串写进文件再 `objdump -D -b binary -m i386:x86-64` 解出来
  （本篇 ④ 的那段汇编就是这么得到的）
- `-O2` 下 GCC 会不会内联掉 `apply` 从而消掉蹦床？（本篇全部实测在 `-O0`）
- ARM64 上的静态链寄存器是哪个、蹦床长什么样
- `PT_GNU_STACK` 在 `fs/binfmt_elf.c` 里的具体处理，以及 `READ_IMPLIES_EXEC` 的触发条件
- Clang 对嵌套函数的态度（**不支持** GNU 嵌套函数，但有 blocks 扩展，机制不同）
- 内核那几种 trampoline 的实现细节（ftrace / BPF 的动态代码分配走的是 `module_alloc`）
