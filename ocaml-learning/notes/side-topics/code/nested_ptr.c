/* 实验组：把嵌套函数的【地址】传出去 —— 这才触发 trampoline（蹦床）
 *
 * 结论：GCC 会在【栈上现场写入 28 字节机器码】当作跳板，
 *       导致整个进程的栈被标成可执行（GNU_STACK = RWE）。
 *
 * 构建与检查：
 *   gcc -O0 -o nested_ptr nested_ptr.c
 *     └─ ld.bfd: warning: requires executable stack
 *   readelf -lW nested_ptr | grep GNU_STACK          # → RWE
 *   objdump -d --no-show-raw-insn nested_ptr | sed -n '/<add_n>:/,/^$/p'
 *   objdump -d --no-show-raw-insn nested_ptr | sed -n '/<adder.0>:/,/^$/p'
 *   objdump -d --no-show-raw-insn nested_ptr | sed -n '/<apply>:/,/^$/p'
 *
 * 两个对照：
 *   1) 把 apply(adder, x) 改成 adder(x)  → 蹦床消失，GNU_STACK 回到 RW
 *   2) gcc -ftrampoline-impl=heap        → 蹦床搬到 mmap 的可执行页，GNU_STACK 为 RW
 *                                          （GCC 14+ 才有此选项）
 *
 * 逐行讲解见上一级目录的 c-nested-functions-trampoline.md
 */
#include <stdio.h>

/* 普通函数：只认「8 字节的裸地址」，call *%rdx，全程不碰 %r10。
 * 它是整件事的「罪魁」—— int (*)(int) 这个类型装不下「代码 + 环境」两样东西。*/
static int apply(int (*f)(int), int x) { return f(x); }

static int add_n(int n, int x)
{
	int adder(int v) { return v + n; }	/* 捕获了 n → 需要静态链 %r10 */
	return apply(adder, x);			/* ★ 就是这一行取了地址，逼出蹦床 */
}

int main(void)
{
	printf("add_n(10, 5) = %d  (期望 15)\n", add_n(10, 5));
	return 0;
}
