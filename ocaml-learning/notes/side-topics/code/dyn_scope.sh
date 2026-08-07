#!/bin/bash
# bash 是动态作用域：f 看到的 x 取决于「谁调用了它」，不是「f 写在哪儿」
f() { echo "f 看到的 x = $x"; }

outer() {
	local x=100
	f
}

x=3
echo "直接调用 f："
f
echo "经由 outer 调用 f："
outer
