# 资源清单与查证状态

> **每条都标了「查证状态」。** ✅ = 2026-08-05 用 WebSearch/WebFetch 实际查过；
> ⚠️ = 凭知识推荐、**未查证**，用之前自己核一下。
>
> 这个区分很重要——别把未查证的当成事实去规划。

---

## 课程

### ✅ Harvard CS153 — Compilers

- **查证状态**：✅ 已查
- **实现语言**：OCaml
- **源语言**：LLVMlite（64 位 LLVM IR 的简化子集）
- **目标**：X86lite（理想化的 x86-64 子集）
- **结构**：8 个作业；**前置作业要求先实现 X86lite 的汇编器和模拟器**
- **入口**：https://groups.seas.harvard.edu/courses/cs153/
- **在路线里的位置**：阶段 2（后端入门主力）
- **缺什么**：不涉及面向对象；寄存器分配覆盖有限

### ✅ Cornell CS 6120 — Advanced Compilers（自学版）

- **查证状态**：✅ 已查
- **形式**：博士生课程，**官方免费自学版**（视频 + 讲义 + 开放式实现任务）
- **内容**：中间表示、数据流分析、经典优化，加 JIT、垃圾回收、并行化
- **工具**：**Bril**（专为教学发明的 IR）+ LLVM
- **语言**：任务**语言无关**，可用 OCaml
- **入口**：https://www.cs.cornell.edu/courses/cs6120/2025sp/self-guided/
  ｜仓库 https://github.com/sampsyo/cs6120
- **在路线里的位置**：阶段 3（补中端）

### ✅ Stanford CS143 — Compilers

- **查证状态**：✅ 已查
- **项目语言**：Cool（Classroom Object-Oriented Language）——**有真正的子类型系统**
- **目标**：**MIPS 汇编 + SPIM 模拟器** ← ⚠️ **架构已死，不要做代码生成部分**
- **结构**：4–5 个作业；2026 年材料仍在更新
- **入口**：https://web.stanford.edu/class/cs143/
- **在路线里的位置**：**降级为参考材料**，只取类型系统部分（`SELF_TYPE`、子类型、对象布局）

### ⚠️ Berkeley CS164 — Programming Languages and Compilers

- **查证状态**：⚠️ **关键信息缺失**
- Fall 2025 由 S. E. Chasins 开设，主页 https://schasins.com/berkeley-cs164-fall-2025/
- **主页上没写实现语言、源语言、目标架构**，只在资源区列了一份 x86-64 汇编参考
- **要用它必须先自己看 syllabus 或课程 GitHub 仓库**。不要按猜测规划

### ⚠️ CMU 15-411 — Compiler Design

- **查证状态**：⚠️ 未查证
- 印象：目标 x86-64，**学生自选实现语言**（历史上 SML/OCaml 常见），材料公开，测试集文化好
- 定位：CS153 的更硬核替代品

---

## 书

### ✅ Nora Sandler《Writing a C Compiler》(No Starch Press, 2024)

- **查证状态**：✅ 已查
- **算法全部用伪代码**，明确设计成「用你喜欢的任何语言实现」→ OCaml 完全适用
- **按章节增量推进**，每章加一个语言特性
- **配套测试集语言无关**（Python 3.8+ 的测试脚本），后面章节会累积跑前面所有章节的测试
- 书里有自己的**三地址码中间表示**，所以中端也覆盖到了
- ⚠️ **后端目标是 x86-64 汇编，不是 LLVM IR**。走 LLVM 路线的话前端+中端章节照用，把最后的代码生成换成打印 `.ll`
- **入口**：https://norasandler.com/book/ ｜ https://nostarch.com/writing-c-compiler
- **在路线里的位置**：阶段 1 的范围约束器 + 测试集来源

### ⚠️《Crafting Interpreters》(Bob Nystrom)

- **查证状态**：⚠️ 未查证（但这本书很有名，风险低）
- 免费在线；**第三部分 clox 是 C 写的字节码虚拟机**，实现的 Lox 是**类式 OO 语言**（含继承和方法分派）
- **在路线里的位置**：阶段 4 的首选，**可替代 CS143 的 Cool 部分**，且没有 MIPS 包袱

### ⚠️ Appel《Modern Compiler Implementation in ML》

- **查证状态**：⚠️ 未查证
- 印象：用 ML 实现 Tiger 编译器，**覆盖完整流水线，包括活跃变量分析和图着色寄存器分配**
- **补的正是 CS153 的短板**（寄存器分配）
- 有 Java/C 版本，但 ML 版是原版，风格和 OCaml 一致

### ⚠️《SSA-based Compiler Design》(SSA Book)

- **查证状态**：⚠️ 未查证
- 印象：免费 PDF。阶段 3 之后想深入 SSA 时用

---

## 工具链

| 工具 | 状态（2026-08-05 实测） | 备注 |
|---|---|---|
| **gcc** | ✅ **15.2.0 已装**（WSL） | 阶段 1 用 `gcc -E` 做预处理 |
| **clang / llc / opt / llvm-as** | ❌ **全部没装** | 阶段 1 的硬前提，`sudo apt install clang llvm` |
| OCaml 工具链 | ✅ 齐全 | 见 `ocaml-learning/docs/env/COMMON.md` |
| menhir / ocamllex | ✅ 已装 | 阶段 1 的语法/词法分析 |

**验证 IR 合法性的白捡工具**（装了 LLVM 之后）：

```bash
llvm-as foo.ll -o /dev/null      # 语法 + 类型检查
opt -passes=verify foo.ll -S     # 结构验证
```

报错精确到行，相当于针对你的编译器输出免费送的测试工具。

---

## 行业现状参考（查证于 2026-08-05）

- [ML Compiler / Runtime Engineer Jobs 2026 Guide](https://machinelearningjobs.co.uk/career-advice/ml-compiler-runtime-engineer-jobs-uk)
- [AI Compiler Engineer Jobs 2026 — Salaries, Skills & Top Companies](https://propelgrad.com/ai-jobs/ai-compiler-engineer)
- [NVIDIA — LLVM and MLIR Compiler Engineer Intern, Fall 2026](https://nvidia.wd5.myworkdayjobs.com/en-US/NVIDIAExternalCareerSite/job/LLVM-and-MLIR-Compiler-Engineer-Intern---Fall-2026_JR2014460)

## MIPS 已死的证据（查证于 2026-08-05）

- [GlobalFoundries to Acquire MIPS（官方新闻稿）](https://mips.com/press-releases/gf-mips/)
- [Another RISC-V firm falls as GlobalFoundries buys MIPS — eeNews](https://www.eenewseurope.com/en/another-risc-v-firm-falls-as-globalfoundries-buys-mips/)

要点：MIPS 公司 2021 年宣布放弃自家 ISA 转投 RISC-V；2025 年 7 月 GlobalFoundries
宣布收购 MIPS，收购的是它的 **RISC-V** 处理器 IP。

## RISC-V 后端资料（查证于 2026-08-05）

**结论：没有 canonical 的教学课**，现有材料是给已经懂的人看的。

- [Boosting RISC-V Application Performance: An 8-Month LLVM Journey — Igalia](https://blogs.igalia.com/compilers/2025/05/05/boosting-risc-v-application-performance-an-8-month-llvm-journey/)
- [A Multi-level Compiler Backend for RISC-V ISA Extensions（CGO 2025）](https://arxiv.org/abs/2502.04063)
