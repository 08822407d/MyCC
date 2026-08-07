/* 对照组：验证 C 的嵌套函数「遮蔽 / 捕获」行为，且【不取地址】
 *
 * 结论：既遮蔽也捕获，和 OCaml 一致；因为没取地址，所以【不生成蹦床】，
 *       GNU_STACK 保持 RW。
 *
 * 构建与检查：
 *   gcc -Wall -Wextra -Wshadow -o nested_fn nested_fn.c
 *   readelf -lW nested_fn | grep GNU_STACK      # → RW
 *   ./nested_fn                                 # → 5 / 9
 *
 * 注意：嵌套函数是 GNU 扩展，不在 C 标准里。
 */
#include <stdio.h>

/* 内层参数与外层参数同名：会不会遮蔽？
 * → 会。-Wshadow 报 "declaration of 'n' shadows a parameter"，结果 5。*/
static int count_shadow(int n)
{
	int go(int acc, int n) { return n <= 0 ? acc : go(acc + 1, n - 1); }
	return go(0, n);
}

/* 内层不同名：能不能看见外层的 n？
 * → 能。count_capture(3) = 3+3+3 = 9，证明 go 拿到了外层的 n。*/
static int count_capture(int n)
{
	int go(int acc, int m) { return m <= 0 ? acc : go(acc + n, m - 1); }
	return go(0, n);
}

int main(void)
{
	printf("shadow  count_shadow(5)  = %d  (期望 5)\n", count_shadow(5));
	printf("capture count_capture(3) = %d  (期望 9)\n", count_capture(3));
	return 0;
}
