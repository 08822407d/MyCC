# 编译器术语表

> **用途**：沿用 `../../ocaml-learning/notes/glossary.md` 的做法 ——
> 术语第一次出现时写成「**粗体中文（English）**」，
> 起因是用户提过「术语和普通中文词在排版上分不开」。
>
> 🔴 **这张表只收「已经解释清楚、用户确认理解了的」。**
> **提到过但没展开的放第二节，别混。** 混了会造成「他懂这个」的错觉，
> 而 `skills-profile.md` 写得很清楚：**编译器理论他是初学者，无正式课程背景。**

## 已经解释清楚的

*（暂无。设计问答刚开始，还没有哪个术语是展开讲过并验证过的。）*

| 中文 | English | 一句话 | 出处 |
|---|---|---|---|

## 提到过但**没有展开**的（⚠️ 别当讲过）

> 这些词已经出现在 `ROADMAP.md` / `resources.md` 里，**但从来没有解释过**。
> 用到它们的时候要意识到：**对他来说这些目前只是名字。**

| 中文 | English | 出现在哪 |
|---|---|---|
| **中间表示** | IR (intermediate representation) | `ROADMAP.md` 阶段 1.5 / 3；「IR 设计能力」是行业需求那节的关键词 |
| **静态单赋值** | SSA (static single assignment) | `ROADMAP.md` 阶段 1.5「做完这一步才会真正理解 SSA 为什么存在」 |
| **phi 节点** | phi node | 决策 004「一个 phi 节点都不写」 |
| **内存到寄存器提升** | `mem2reg` | 决策 004 的核心技巧 |
| **数据流分析** | dataflow analysis | `ROADMAP.md` 阶段 3 |
| **常量折叠 / 死代码消除 / 常量传播** | constant folding / DCE / constant propagation | `ROADMAP.md` 阶段 1.5 的三个 pass |
| **寄存器分配（图着色）** | register allocation (graph coloring) | `resources.md` 里 Appel 那条；CS153 的短板 |
| **指令选择** | instruction selection | 决策 004 的「代价」一节 |
| **虚函数表** | vtable | `skills-profile.md`：⭐ **这个他不用解释** —— 内核的 `struct file_operations` 就是手写 vtable |
| **动态分派** | dynamic dispatch | `ROADMAP.md` 阶段 4 |
| **卫生宏** | hygienic macro | 决策 002 的「值得读懂它烂在哪」 |
| **lexer hack** | the lexer hack | `ROADMAP.md`：C 的 typedef 歧义，决策 003 点名的可砍项 |
| **声明符螺旋** | declarator spiral | 同上 |
| **整型提升** | integer promotion | 同上 |
| **数组/函数退化** | array/function decay | 同上 |
