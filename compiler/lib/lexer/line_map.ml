(* line_map.ml — 行映射表（决策 006）：.i 物理行 → 原始 .c 位置。
   GCC libcpp line-map / Clang SourceManager 的极简版：
   词法层只带物理位置，翻译推迟到打印诊断的时刻。 *)

type entry = {
  phys_line : int;       (* 行标记之后第一行的 .i 物理行号 *)
  file : string;         (* 原始文件名 *)
  orig_line : int;       (* phys_line 对应的原始行号（行标记里的 N） *)
  system_header : bool;  (* 行标记标志 3（决策 006：区间属性存表，不占 token） *)
}

type t = {
  mutable arr : entry array;
  mutable len : int;
}

let create () = { arr = [||]; len = 0 }

(* 行标记按物理行顺序到达，phys_line 严格递增，直接追加即可 *)
let add t ~phys_line ~file ~orig_line ~system_header =
  let e = { phys_line; file; orig_line; system_header } in
  if t.len = Array.length t.arr then begin
    let grown = Array.make (max 16 (2 * t.len)) e in
    Array.blit t.arr 0 grown 0 t.len;
    t.arr <- grown
  end;
  t.arr.(t.len) <- e;
  t.len <- t.len + 1

(* 物理行 → (原始文件, 原始行, 是否系统头)。
   二分找 phys_line <= 目标行 的最后一条；
   落在第一条之前（正常 .i 不会发生）用 fallback 原样返回。 *)
let translate t ~phys_line ~fallback =
  if t.len = 0 || t.arr.(0).phys_line > phys_line then
    (fallback, phys_line, false)
  else begin
    let lo = ref 0 and hi = ref (t.len - 1) in
    while !lo < !hi do
      let mid = (!lo + !hi + 1) / 2 in
      if t.arr.(mid).phys_line <= phys_line then lo := mid else hi := mid - 1
    done;
    let e = t.arr.(!lo) in
    (e.file, e.orig_line + (phys_line - e.phys_line), e.system_header)
  end
