#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 本项目所有 OCaml 构建/运行/求值操作的唯一入口。
#
# 为什么要有这个脚本：
#   1) Claude 每次执行时不用现场拼命令，直接调固定子命令。
#   2) 免授权白名单只需放行这一个脚本，而不是放行任意命令。
#   3) 路径全部由脚本自身位置推导，所以整个文件夹随便挪，脚本照样能用。
#   4) **跨平台**：同一条命令在 Windows 笔记本和 Ubuntu PC 上都能用（见下面的自动转发）。
#
# 用法（两台机器完全一样）：
#     bash ./scripts/ocaml.sh <子命令> [参数...]
#
# 在 Windows 上，脚本会自己 exec 进 WSL；不需要手写 `wsl -d Ubuntu --` 前缀。
# ---------------------------------------------------------------------------
set -uo pipefail

# --- 平台识别 -------------------------------------------------------------
# win-gitbash : Windows 侧的 Git Bash / MSYS —— 这里没有 OCaml，要转发进 WSL
# wsl         : WSL2 里的 Linux —— 有 OCaml
# linux       : 原生 Linux（Ubuntu PC）—— 有 OCaml
detect_platform() {
  case "${OSTYPE:-}" in
    msys* | cygwin* | win32*) echo win-gitbash; return ;;
  esac
  case "$(uname -s 2>/dev/null || echo unknown)" in
    MINGW* | MSYS* | CYGWIN*) echo win-gitbash; return ;;
  esac
  if grep -qi microsoft /proc/version 2>/dev/null; then
    echo wsl
  else
    echo linux
  fi
}

PLATFORM="$(detect_platform)"

# --- Windows 自动转发 ------------------------------------------------------
# 在 Git Bash 里被调用时，把自己原样丢进 WSL 再跑一遍。
# WSL 会继承当前工作目录（D:\... → /mnt/d/...），所以相对路径调用不用改。
if [ "$PLATFORM" = "win-gitbash" ]; then
  self="$0"
  # Git Bash 的绝对路径是 /d/xxx，WSL 里对应 /mnt/d/xxx；相对路径原样透传。
  case "$self" in
    /?/*) self="/mnt$self" ;;
  esac
  exec wsl.exe -d "${WSL_DISTRO:-Ubuntu}" -- bash "$self" "$@"
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EX="$ROOT/exercises"

# opam 环境。登录 shell 里已经由 ~/.profile 装好，但这里再确保一次，
# 免得以非登录方式调用时找不到 dune。
if command -v opam >/dev/null 2>&1; then
  eval "$(opam env 2>/dev/null)" || true
fi

die() { echo "错误: $*" >&2; exit 1; }

need_dune() {
  command -v dune >/dev/null 2>&1 || die "找不到 dune。先跑 'bash ./scripts/ocaml.sh check' 看环境。"
}

usage() {
  cat <<'EOF'
用法: bash ./scripts/ocaml.sh <子命令> [参数...]
      （Windows 上也是这一条，脚本会自己转进 WSL）

  check              环境自检（当前平台、编译器/工具版本、路径）
  platform           只打印当前平台，一行
  list               列出所有练习
  new <名字>         新建一个练习目录（含 dune / main.ml 骨架 / README / SOLUTION）
  build [名字]       构建；省略名字则构建全部
  run <名字> [参数]  构建并运行某个练习
  test [名字]        跑测试；省略名字则跑全部
  eval <代码>        把一段 OCaml 丢进顶层求值，会打印出类型和值（教学用）
  evalfile <文件>    同上，但从文件读取
  fmt                格式化全部源码
  clean              删除构建产物
  repl               启动 utop 交互环境（需要交互终端）
EOF
}

cmd_platform() {
  case "$PLATFORM" in
    wsl)   echo "wsl   (Windows 笔记本里的 WSL2 Ubuntu)" ;;
    linux) echo "linux (原生 Linux，Ubuntu PC)" ;;
    *)     echo "$PLATFORM" ;;
  esac
}

# 取某个工具的版本号。工具不在就回「缺失」，而不是留空或报错。
ver() {
  local tool="$1"; shift
  command -v "$tool" >/dev/null 2>&1 || { echo "缺失"; return; }
  "$tool" "$@" 2>/dev/null | head -1
}

# utop 不认 --version，而且 -version 输出的是一整句话，得把版本号抠出来。
ver_utop() {
  command -v utop >/dev/null 2>&1 || { echo "缺失"; return; }
  utop -version 2>/dev/null | sed -n 's/.*, version \([^,]*\),.*/\1/p'
}

cmd_check() {
  echo "当前平台: $(cmd_platform)"
  echo "项目根目录: $ROOT"
  echo
  echo "  工具路径（都应该在 opam switch 里，不是 /usr/bin）:"
  for t in ocaml ocamlc dune utop ocamlformat menhir ocamllex ocamllsp opam; do
    if p=$(command -v "$t" 2>/dev/null); then
      printf '    %-12s %s\n' "$t" "$p"
    else
      printf '    %-12s 缺失\n' "$t"
    fi
  done
  echo
  # 下面这几项要和 docs/env/COMMON.md 的版本口径逐条对得上。
  # 两台机器交替使用，版本漂了会出怪事，所以宁可全列出来。
  echo "  版本（对照 docs/env/COMMON.md 的口径）:"
  printf '    %-18s %s\n' "OCaml"            "$(ver ocamlc -version)"
  printf '    %-18s %s\n' "dune"             "$(ver dune --version)"
  printf '    %-18s %s\n' "opam"             "$(ver opam --version)"
  printf '    %-18s %s\n' "opam switch"      "$(opam switch show 2>/dev/null || echo '?')"
  printf '    %-18s %s\n' "utop"             "$(ver_utop)"
  printf '    %-18s %s\n' "ocaml-lsp-server" "$(ver ocamllsp --version)"
  printf '    %-18s %s\n' "ocamlformat"      "$(ver ocamlformat --version)"
  printf '    %-18s %s\n' "menhir"           "$(ver menhir --version | sed 's/^menhir, version //')"
}

cmd_list() {
  [ -d "$EX" ] || { echo "(还没有练习)"; return; }
  local found=0
  for d in "$EX"/*/; do
    [ -d "$d" ] || continue
    local name; name="$(basename "$d")"
    # 跳过 _build 之类的非练习目录（dune 也是按这个前缀约定忽略的）
    case "$name" in _* | .*) continue ;; esac
    found=1
    local desc=""
    # 练习目录里如果有 README.md，取第一行标题当描述
    [ -f "$d/README.md" ] && desc="$(head -1 "$d/README.md" | sed 's/^#\+ *//')"
    printf '  %-28s %s\n' "$name" "$desc"
  done
  [ "$found" = 0 ] && echo "  (还没有练习)"
  return 0
}

cmd_new() {
  local name="${1:-}"
  [ -n "$name" ] || die "要给练习起个名字，比如: new ex01_let_binding"
  local dir="$EX/$name"
  [ -e "$dir" ] && die "'$name' 已经存在了。"
  mkdir -p "$dir"

  cat > "$dir/dune" <<'EOF'
(executable
 (name main))
EOF

  cat > "$dir/main.ml" <<EOF
(* $name
   ------------------------------------------------------------------
   只需要改下面「你的代码」那一段。分隔线以下是自测，别动。
   写完跟 Claude 说一声，它会自动构建并运行。
   ------------------------------------------------------------------ *)

(* ======================= 你的代码（改这里） ======================= *)

(* TODO 1: 题目见 README.md *)
let todo1 (n : int) : int = failwith "TODO 1"

(* ===================== 分隔线以下别改 ===================== *)

let check name to_s expected thunk =
  match thunk () with
  | actual ->
    if actual = expected then Printf.printf "  [OK] %s\n" name
    else
      Printf.printf "  [XX] %s -> 期望 %s，实际 %s\n" name (to_s expected)
        (to_s actual)
  | exception e ->
    Printf.printf "  [--] %s -> 还没做（%s）\n" name (Printexc.to_string e)

let () =
  print_endline "$name 自测:";
  check "todo1 0" string_of_int 0 (fun () -> todo1 0)
EOF

  cat > "$dir/README.md" <<EOF
# $name

题目：（待填写）
EOF

  cat > "$dir/SOLUTION.md" <<EOF
# $name 参考答案

（待填写。**自己写完之前别看。**）
EOF

  echo "已创建 $dir"
  echo "  要编辑的文件: $dir/main.ml"
}

cmd_build() {
  need_dune
  cd "$EX" || die "找不到 exercises 目录"
  if [ -n "${1:-}" ]; then
    dune build "./$1" 2>&1
  else
    dune build 2>&1
  fi
}

cmd_run() {
  need_dune
  local name="${1:-}"
  [ -n "$name" ] || die "要指定练习名字。可以先跑 'list' 看有哪些。"
  shift
  cd "$EX" || die "找不到 exercises 目录"
  [ -d "$name" ] || die "没有这个练习: $name"
  dune build "./$name" 2>&1 || return 1
  echo "--- 运行 $name ---"
  dune exec --no-build "./$name/main.exe" -- "$@" 2>&1
}

cmd_test() {
  need_dune
  cd "$EX" || die "找不到 exercises 目录"
  if [ -n "${1:-}" ]; then
    dune test "./$1" 2>&1
  else
    dune test 2>&1
  fi
}

# 把一段代码送进 OCaml 顶层。顶层会回显每个定义的类型和值，
# 这正是教学时最想看到的东西（比如 val x : int = 5）。
run_toplevel() {
  local code="$1"
  command -v ocaml >/dev/null 2>&1 || die "找不到 ocaml"
  # 顶层需要每段以 ;; 结尾才会求值；末尾没有就补一个。
  case "$(printf '%s' "$code" | tr -d '[:space:]' | tail -c 2)" in
    ';;') ;;
    *) code="$code
;;" ;;
  esac
  printf '%s\n' "$code" | ocaml -noprompt -no-version -init /dev/null 2>&1 \
    | sed '/^$/d'
}

cmd_eval() {
  [ $# -gt 0 ] || die "要给一段代码，比如: eval 'let x = 5'"
  run_toplevel "$*"
}

cmd_evalfile() {
  local f="${1:-}"
  [ -n "$f" ] && [ -f "$f" ] || die "文件不存在: ${f:-<空>}"
  run_toplevel "$(cat "$f")"
}

cmd_fmt() {
  need_dune
  cd "$EX" || die "找不到 exercises 目录"
  dune build @fmt --auto-promote 2>&1 | grep -v '^$' || true
  echo "格式化完成"
}

cmd_clean() {
  need_dune
  cd "$EX" && dune clean 2>&1
  echo "已清理构建产物"
}

cmd_repl() {
  command -v utop >/dev/null 2>&1 || die "找不到 utop"
  cd "$EX" && utop
}

case "${1:-}" in
  check)    shift; cmd_check "$@" ;;
  platform) shift; cmd_platform "$@" ;;
  list)     shift; cmd_list "$@" ;;
  new)      shift; cmd_new "$@" ;;
  build)    shift; cmd_build "$@" ;;
  run)      shift; cmd_run "$@" ;;
  test)     shift; cmd_test "$@" ;;
  eval)     shift; cmd_eval "$@" ;;
  evalfile) shift; cmd_evalfile "$@" ;;
  fmt)      shift; cmd_fmt "$@" ;;
  clean)    shift; cmd_clean "$@" ;;
  repl)     shift; cmd_repl "$@" ;;
  ""|-h|--help|help) usage ;;
  *) echo "未知子命令: $1" >&2; echo; usage; exit 1 ;;
esac
