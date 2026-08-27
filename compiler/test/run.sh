#!/usr/bin/env bash
# 词法验收 T0/T1/T2（决策 008；用例清单与基线见 ../compiler-roadmap/spec/lexer/DESIGN.md §6）
# 用法: bash test/run.sh
set -u
cd "$(dirname "$0")/.."
command -v dune >/dev/null 2>&1 || export PATH="$HOME/.opam/default/bin:$PATH"

dune build 2>&1 || { echo "❌ 构建失败"; exit 1; }
BIN=_build/default/bin/main.exe
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0
ok() { pass=$((pass+1)); }
ko() { fail=$((fail+1)); echo "❌ $1"; }

# ============ T0：自造陷阱用例 ============

# --- 合法输入，逐 token 全文比对 ---
cat > "$TMP/valid.i" <<'EOF'
int a = 0x1p-3 ;
unsigned b = 0b1010u ;
long c = 1LL ;
int o = 0777 ;
double d = .5 ;
double e = 1e+2 ;
x >>= 1 ;
s = "a\x41\"b" ;
c2 = L'a' ;
u8s = u8"你好 wörld" ;
url = "http://x" ;
arr<:0:> = 1 ;
p = cond ? a : b ;
EOF
cat > "$TMP/valid.expect" <<'EOF'
int
a
=
0x1p-3
;
unsigned
b
=
0b1010u
;
long
c
=
1LL
;
int
o
=
0777
;
double
d
=
.5
;
double
e
=
1e+2
;
x
>>=
1
;
s
=
"a\x41\"b"
;
c2
=
L'a'
;
u8s
=
u8"你好 wörld"
;
url
=
"http://x"
;
arr
[
0
]
=
1
;
p
=
cond
?
a
:
b
;
EOF
if "$BIN" "$TMP/valid.i" > "$TMP/valid.out" 2>"$TMP/valid.err"; then
  if diff -q "$TMP/valid.expect" "$TMP/valid.out" >/dev/null; then ok
  else ko "T0 valid: token 流不符"; diff "$TMP/valid.expect" "$TMP/valid.out" | head -10; fi
else ko "T0 valid: 意外报错: $(cat "$TMP/valid.err")"; fi

# --- 应报错的用例：t0_err 名字 期望子串 源码各行... ---
t0_err() {
  local name=$1 sub=$2; shift 2
  printf '%s\n' "$@" > "$TMP/$name.i"
  if "$BIN" "$TMP/$name.i" >/dev/null 2>"$TMP/$name.err"; then
    ko "T0 $name: 应报错但通过了"
  elif grep -qF -- "$sub" "$TMP/$name.err"; then ok
  else ko "T0 $name: 消息不含「$sub」→ $(cat "$TMP/$name.err")"; fi
}

t0_err ppnum1  "非法数字字面量 '0x1e+2'" 'int c = 0x1e+2;'
t0_err ppnum2  "非法数字字面量 '123abc'" 'int c = 123abc;'
t0_err ppnum3  "非法数字字面量 '0x1.8'"  'double d = 0x1.8;'
t0_err ppnum4  "非法数字字面量 '1lL'"    'long c = 1lL;'
t0_err unterm  "未闭合的字符串"          'char *s = "abc'
t0_err untermc "未闭合的字符字面量"      "int c = 'a"
t0_err comm1   "块注释"                  'int /* c */ x;'
t0_err comm2   "行注释"                  'int x; // c'
t0_err bslash  "行接续残留"              'int spl\' 'iced;'
t0_err direc   "残留 #define 指令"       '#define X 1' 'int x;'
t0_err midhash "行中出现 '#'"            'int a = # ;'
t0_err digrhash "%:"                     'int a %: b;'
t0_err illchar "非法字符"                'int @;'

# --- 行映射：报错位置指回原始文件（差一格专项：marker 后第 2 行） ---
cat > "$TMP/lmap.i" <<'EOF'
# 10 "orig.c"
int x;
int @;
EOF
if "$BIN" "$TMP/lmap.i" >/dev/null 2>"$TMP/lmap.err"; then
  ko "T0 lmap: 应报错但通过了"
elif grep -qF -- "orig.c:11" "$TMP/lmap.err"; then ok
else ko "T0 lmap: 位置不对 → $(cat "$TMP/lmap.err")"; fi

# --- 系统头标志（-l 模式） ---
cat > "$TMP/sys.i" <<'EOF'
# 7 "sys.h" 1 3
int x;
EOF
if "$BIN" -l "$TMP/sys.i" 2>/dev/null | head -1 | grep -qF -- "sys.h:7:1 (系统头)"; then ok
else ko "T0 sys-header 标志: $("$BIN" -l "$TMP/sys.i" | head -1)"; fi

# --- #pragma 整行吞掉 ---
cat > "$TMP/prag.i" <<'EOF'
#pragma GCC diagnostic push
int x;
EOF
if [ "$("$BIN" "$TMP/prag.i")" = "$(printf 'int\nx\n;')" ]; then ok
else ko "T0 pragma 吞行"; fi

# ============ T1：真实 .i 基线（2026-08-26 实测：3122 / 23853） ============
printf '#include <stdio.h>\nint main(void){printf("hello\\n");return 0;}\n' > "$TMP/hello.c"
printf '#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n#include <math.h>\n#include <pthread.h>\n#include <signal.h>\n#include <time.h>\nint main(void){return 0;}\n' > "$TMP/big.c"
gcc -E "$TMP/hello.c" -o "$TMP/hello.i" && gcc -E "$TMP/big.c" -o "$TMP/big.i" \
  || { echo "❌ gcc -E 失败"; exit 1; }

for spec in hello:3122 big:23853; do
  name=${spec%%:*}; want=${spec##*:}
  if "$BIN" "$TMP/$name.i" > "$TMP/$name.toks" 2>"$TMP/$name.t1err"; then
    got=$(wc -l < "$TMP/$name.toks")
    if [ "$got" -eq "$want" ]; then ok
    else ko "T1 $name.i: $got 个 token ≠ 基线 $want"; fi
  else ko "T1 $name.i: 报错 → $(cat "$TMP/$name.t1err")"; fi
done

# ============ T2（主标准）：token 流每行一个 → gcc 重新编译零诊断 ============
for name in hello big; do
  if gcc -fsyntax-only -x c "$TMP/$name.toks" 2>"$TMP/$name.rt.err"; then ok
  else ko "T2 $name: $(head -3 "$TMP/$name.rt.err")"; fi
done

echo
echo "通过 $pass，失败 $fail"
[ "$fail" -eq 0 ]
