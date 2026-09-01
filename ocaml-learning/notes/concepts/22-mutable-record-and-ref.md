# 22. 可变记录（`mutable` / `<-`）与 `ref` 的真面目

> 2026-09-01 讲。D1 的倒数第二件。主题是「**OCaml 里怎么搞可变状态**」。
> 讲法：**先讲可变记录，再回马枪揭示 `ref` 就是它** —— 效果好，因为他早就在用 `ref` 了。

---

## 22.1 `mutable` 字段 + `<-`

```ocaml
type account = { owner : string; mutable balance : int }

let acc = { owner = "cheyh"; balance = 1000 }
let () = acc.balance <- acc.balance - 300
```

```
val acc : account = {owner = "cheyh"; balance = 700}
```

> **可变字段（mutable field）** — 字段前加 `mutable`，这个字段就允许被就地修改。
> **没标 `mutable` 的字段永远不能改。**
> **`<-`** — 赋值运算符，把右边的值写进左边那个可变字段。

### C 对照（默认值是反的）

```c
struct account {
    const char *owner;      /* 想拦住修改，得自己加 const */
    int         balance;
};
acc.balance = acc.balance - 300;
```

| | C | OCaml |
|---|---|---|
| 默认 | **全都能改**，想拦住要加 `const` | **全都不能改**，想放开要加 `mutable` |

**OCaml 里「可变」是要申请的。**

`mutable` 是**编译期**的许可标记，`<-` 是**运行期**真正往内存里写。

### 三条边界（都实测过）

**① 没标 `mutable` 的字段改不动，编译期就挡住**

```
Error: The record field owner is not mutable
```

**② 名字本身仍然不可变**

```ocaml
let () = acc <- other
```
```
Error: The value acc is not an instance variable
```

`<-` 只能作用在「某个东西的可变字段」上，不能作用在 `let` 绑的名字上。
**`let` 绑定永远不可变**；`mutable` 放开的是**记录内部的一个格子**，不是那个名字。

C 里的对照：
```c
struct account *p = &acc;
p->balance = 700;      /* ✅ 改结构体里的格子 —— OCaml 有 */
p = &other;            /* ✅ C 允许改指针本身 —— OCaml 没有 */
```

**③ `<-` 的结果是 `unit`** → 所以它是「一个动作」，可以用 `;` 串起来。

---

## 22.2 回马枪：`ref` 就是一个带 `mutable` 字段的记录

标准库里的定义只有一行：

```ocaml
type 'a ref = { mutable contents : 'a }
```

**这不是比喻。** 实测——直接用记录字面量造 `ref`、直接改它的字段：

```ocaml
let r : int ref = { contents = 5 }     (* 没用 ref 函数 *)
let peek = !r
let () = r.contents <- 99              (* 没用 := *)
let peek2 = !r

let r2 = ref 7
let inside = r2.contents               (* 反过来也成立 *)
```

```
val peek   : int = 5
val peek2  : int = 99
val r2     : int ref = {contents = 7}
val inside : int = 7
```

| 你写的 | 实际是 |
|---|---|
| `ref v` | `{ contents = v }` |
| `!r` | `r.contents` |
| `r := v` | `r.contents <- v` |

顶层回显 `ref` 时直接打印成 `{contents = 7}`，**它从来没打算瞒你**。

---

## 22.3 「不给初值」怎么写 —— 不能，OCaml 没有未初始化

**他主动问的**（很 C 的问题）。三种尝试实测：

| 写法 | 结果 |
|---|---|
| `let r : int ref` | `Error: Syntax error` —— `let 名字` 后必须有 `=` 和值 |
| `let r = ref` | ⚠️ **能编译，但 `r` 是个函数**：`val r : 'a -> 'a ref = <fun>` |
| `let a = { }`（记录） | `Error: Syntax error` —— 记录字面量必须填满每个字段 |

**为什么**：C 里 `int x;` 有三种下场（栈上垃圾 / 静态区 0 / 警告），
**未初始化读**是 C 最贵的一类 bug。**OCaml 干脆不给这个选项。**

### 实际要「先占位后填」怎么办（按推荐度）

**① 首选：把 `let` 挪到有值的地方。** OCaml 的 `let … in` 可以在任何位置引入名字，
不像老 C89 逼你在块首声明。**先问一句「我真的需要一个可变的格子吗」，八成不需要。**

```ocaml
let result = if cond then a else b in ...   (* 而不是先声明 result 再赋值 *)
```

**② 真需要「还没有」这个状态：`ref None`**（= C 的 `T *p = NULL`）

```ocaml
let slot = ref None
let () = slot := Some 42
let taken = match !slot with Some v -> v | None -> 0
```

好处：**「还没设」被编码进了类型**，`None` 和 `Some 0` 是两个不同的东西。

**③ 哨兵初值 `ref 0` / `ref ""`** —— 计数器这种 0 本来就正确时可以用。
但如果 0 是假初值，就把 C 的老毛病搬过来了：**分不清「还没设」和「真的是 0」**。

### 预防针：`'_weak1`

单独写 `let slot = ref None`：

```
val slot : '_weak1 option ref = {contents = None}
```

`'_weak1` 不是错误，意思是「**类型还没定下来，但一旦定下来就不能变**」。
这叫**弱多态**，和 `'a` 多态**不是一回事**。**先不深挖**，看到不用慌。

---

## 22.4 `ref` 能装什么 —— 全部（他问的）

```
val r_str  : string ref         = {contents = "hello"}
val r_list : int list ref       = {contents = [1; 2; 3]}
val r_pair : (string * int) ref = {contents = ("a", 1)}
val r_opt  : int option ref     = {contents = Some 5}
val r_fn   : (int -> int) ref   = {contents = <fun>}      ← 相当于 C 的函数指针
val r_ref  : int ref ref        = {contents = {contents = 0}}
val r_unit : unit ref           = {contents = ()}
val r_rec  : acct ref           = {contents = {owner = "cheyh"; balance = 10}}
```

签名就是 `ref : 'a -> 'a ref`，**没有任何类型限制**。

### 三条注意

**① `ref` 换的是「装的是谁」，不是让装的东西变可变**（最容易误会的一条）

```ocaml
let r = ref [ 1; 2; 3 ]
let () = r := [ 9; 9 ]       (* ✅ 整张表换掉 *)
```
但**改不了表里的某个元素**——列表是不可变的，装进 `ref` 也还是不可变的。

> **`int list ref` ≈ C 的 `const int *`** —— **指针可变，被指的东西只读。**
> ```c
> const int *p;
> p = other;         /*  ✅  ≈  r := [9; 9]     */
> p[0] = 9;          /*  ❌  列表压根没这个操作  */
> ```

**反过来**：装进去的东西自己带 `mutable` 就能改里面——**但那是记录给的，不是 `ref` 给的**：

```ocaml
let r = ref { owner = "cheyh"; balance = 10 }
let () = !r.balance <- 99                      (* 改里面 ← mutable *)
let () = r := { owner = "x"; balance = 0 }     (* 换整个 ← ref    *)
```
```
val now  : acct = {owner = "cheyh"; balance = 99}
val now2 : acct = {owner = "x"; balance = 0}
```

**② `let b = a` 是两个名字一个盒子**

```ocaml
let a = ref 0
let b = a            (* 别名 *)
let c = ref !a       (* 复制 *)
let () = b := 9
```
```
val a_now : int = 9      ← a 也变了
val b_now : int = 9
val c_now : int = 0      ← c 没变
```

C 里一模一样：`int *b = a;`（别名）vs `int c = *a;`（复制）。
**要复制内容就写 `ref !a`，`= a` 永远是共享。**

⚠️ 这不违反「`let` 不可变」——不可变的是**名字到盒子的绑定**，盒子里的内容从来就是可变的。

**③ `=` 和 `==` 在 `ref` 上真的不一样**

```ocaml
let x = ref 1  and y = ref 1
let z = x
```
```
x =  y   →  true     (* 结构相等：拆开比内容 *)
x == y   →  false    (* 物理相等：是不是同一块内存 *)
x == z   →  true
```

> C 习惯清单里那条「`==` 判相等是错的」**依然成立**（日常判等一律 `=`）。
> 但 `ref` 是 `==` 少数**真有意义**的地方——问「是不是同一个盒子」。**不确定就用 `=`。**

### 一个坑：`ref []` / `ref None` 的类型会被第一次使用定死

```ocaml
let box = ref []
let () = box := [ 1; 2 ]      (* 到这里定死成 int list *)
let () = box := [ "a" ]       (* ❌ *)
```
```
Error: This constant has type string but an expression was expected of type int
```

就是 `'_weak1` 的后果：**一个 `ref` 只能给一种类型用**。

---

## 22.5 判据：什么时候用 `ref`，什么时候用 `mutable` 记录

**他自己给的答案**（方向对，但只答了一半）：

> 「整个换值的时候用 ref，只想换部分值的时候用 mutable」

**补上的那一半：**

> **`mutable` 记录能规定「哪些字段永远不许换」；`ref` 表达不了这个约束。**

实测对照——用 `ref` 装不可变记录时，**谁都能把 `owner` 一起换掉，编译器不拦**：

```ocaml
type acct = { owner : string; balance : int }
let r = ref { owner = "cheyh"; balance = 1000 }
let () = r := { !r with balance = 700 }            (* 只改余额 *)
let () = r := { owner = "someone"; balance = 0 }   (* owner 也换了，没人拦 *)
```

换成 `mutable` 记录，**编译期挡住**：

```
Error: The record field owner is not mutable
```

**`mutable` 是逐字段发许可证，`ref` 是整个盒子一张通行证。**

还有一条他没提到的：**命名**。三个 `int ref` 只能靠变量名分辨；记录自带字段名。

| 情况 | 用 |
|---|---|
| 一个孤立的会变的量（计数器、开关、累加器） | **`ref`** |
| 一个「东西」有多个属性，**一部分**会变、**一部分**必须钉死 | **`mutable` 记录** |
| 临时的、活不过一个函数的 | **`ref`** |
| 长期存在、要传来传去的数据结构 | **记录** |

> ⚠️ **两个都要少用。** OCaml 的默认路线是不可变 + `with` 函数式更新（ex04 写过）。
> 只有「就地修改」真的更自然时才开可变——状态机、缓存、性能热点。

---

## 教学备注

- **「回马枪」的顺序是对的**：先教 `mutable`/`<-` 的语法，再揭示 `ref` 就是它。
  反过来（先说 ref 是记录）会变成一句没有落点的知识。
- 「不给初值怎么写」**是他自己问的**，是很自然的 C 迁移问题，答案本身
  （OCaml 没有未初始化）比语法更重要。
- 他关于 `ref` vs `mutable` 的判断**又是「局部对、整体漏一块」**：
  答对了「部分 vs 整体」，漏了「能钉死哪些」。**先肯定再补**，他接受得很顺。
