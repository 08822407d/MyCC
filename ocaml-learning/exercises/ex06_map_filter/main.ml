(* ex06_map_filter — 用 map / filter 代替手写递归
   ------------------------------------------------------------------
   这题没有 match 骨架，因为大部分答案是【一行】。
   前两题是把 ex03 你自己写的递归版重写一遍，注释里附了你当时的原文，
   写完对照着看差别 —— 这才是这道题真正的目的。

   只改下面「你的代码」那一段，把 failwith 换成真正的实现。
   分隔线以下是自测代码，别改。

   ⛔ 这题只用 List.map / List.filter / List.length。
      不用 fold（还没讲）、不用 option、不用自己定义类型。
   ------------------------------------------------------------------ *)

(* ======================= 你的代码（改这里） ======================= *)

(* ─────────── 第一部分：把 ex03 的两题重写 ─────────── *)

(* TODO 1：数一数列表里有几个偶数。
   例：count_evens [1; 2; 3; 4]  应得到  2

   你在 ex03 里写的是：
     let rec count_evens (lst : int list) : int =
       match lst with
       | [] -> 0
       | x :: rest -> (if x mod 2 = 0 then 1 else 0) + count_evens rest

   现在用 filter 重写。提示：先挑出偶数，再问「有几个」。 *)
let count_evens (lst : int list) : int =
  List.length (List.filter (fun x -> x mod 2 = 0) lst)

(* TODO 2：把每个元素乘以 2，返回新表。
   例：double_all [1; 2; 3]  应得到  [2; 4; 6]

   你在 ex03 里写的是：
     let rec double_all (lst : int list) : int list =
       match lst with
       | [] -> []
       | x :: rest -> (x * 2) :: double_all rest

   现在用 map 重写。 *)
let double_all (lst : int list) : int list = List.map (fun x -> x * 2) lst

(* ─────────── 第二部分：map 会改类型 ─────────── *)

(* TODO 3：把整数表变成字符串表。
   例：to_strings [1; 2; 3]  应得到  ["1"; "2"; "3"]

   注意返回类型和参数类型不一样 —— 这是 map 的 'a -> 'b 在起作用，
   filter 做不到这件事。 *)
let to_strings (lst : int list) : string list = List.map string_of_int lst

(* TODO 4：把字符串表变成它们各自的长度。
   例：lengths ["a"; "abc"; ""]  应得到  [1; 3; 0]

   提示：String.length : string -> int *)
let lengths (lst : string list) : int list = List.map String.length lst

(* ─────────── 第三部分：传进去的函数可以捕获外层变量 ─────────── *)

(* TODO 5：只留下长度【严格大于】n 的字符串。
   例：keep_long 2 ["a"; "abc"; "ab"; "abcd"]  应得到  ["abc"; "abcd"]

   ⚠️ 这题的关键：你写的那个判断函数里要用到 n，而 n 是外层的参数。
      这就是【闭包】—— C 的 qsort comparator 做不到，得靠全局变量或 qsort_r。 *)
let keep_long (n : int) (lst : string list) : string list =
  List.filter (fun x -> String.length x > n) lst

(* TODO 6：把每个元素都加上 k。
   例：shift 10 [1; 2; 3]  应得到  [11; 12; 13]
       shift (-1) [1; 2]   应得到  [0; 1] *)
let shift (k : int) (lst : int list) : int list = List.map (fun x -> x + k) lst

(* ─────────── 第四部分：自己写一个高阶函数 ─────────── *)

(* TODO 7：数一数表里有几个元素满足 pred。
   例：count_matching (fun x -> x > 2) [1; 2; 3; 4]        应得到  2
       count_matching (fun s -> s <> "") ["a"; ""; "b"]    应得到  2

   ⚠️ 前六题你都在【用】高阶函数，这题是【写】一个 ——
      pred 是一个参数，它自己是个函数。

   ⚠️ 元素类型是 'a，所以你不能对元素做任何类型相关的操作，
      只能把它交给 pred 去判断。 *)
let count_matching (pred : 'a -> bool) (lst : 'a list) : int =
  List.length (List.filter pred lst)

(* TODO 8：把大于 0 的元素挑出来，再各自乘以 2。
   例：pos_doubled [3; -1; 0; 5]  应得到  [6; 10]
       pos_doubled [-2; -3]       应得到  []

   ⚠️ 顺序有讲究：先挑再变，还是先变再挑？两种在这题上结果一样吗？
      想一想再写（写完可以把顺序换过来试试，看测试还过不过）。 *)
let pos_doubled (lst : int list) : int list =
  List.map (fun x -> x * 2) (List.filter (fun x -> x > 0) lst)

(* ===================== 分隔线以下别改 ===================== *)

let check name to_s expected thunk =
  match thunk () with
  | actual ->
      if actual = expected then Printf.printf "  [OK] %s\n" name
      else Printf.printf "  [XX] %s -> 期望 %s，实际 %s\n" name (to_s expected) (to_s actual)
  | exception e -> Printf.printf "  [--] %s -> 还没做（%s）\n" name (Printexc.to_string e)

let si = string_of_int
let s_il l = "[" ^ String.concat "; " (List.map string_of_int l) ^ "]"
let s_sl l = "[" ^ String.concat "; " (List.map (Printf.sprintf "%S") l) ^ "]"

let () =
  print_endline "ex06_map_filter 自测:";

  print_endline " -- 重写 ex03 --";
  check "count_evens [1;2;3;4]" si 2 (fun () -> count_evens [ 1; 2; 3; 4 ]);
  check "count_evens [1;3]" si 0 (fun () -> count_evens [ 1; 3 ]);
  check "count_evens []" si 0 (fun () -> count_evens []);
  check "double_all [1;2;3]" s_il [ 2; 4; 6 ] (fun () -> double_all [ 1; 2; 3 ]);
  check "double_all []" s_il [] (fun () -> double_all []);

  print_endline " -- map 改类型 --";
  check "to_strings [1;2;3]" s_sl [ "1"; "2"; "3" ] (fun () -> to_strings [ 1; 2; 3 ]);
  check "lengths [\"a\";\"abc\";\"\"]" s_il [ 1; 3; 0 ] (fun () ->
      lengths [ "a"; "abc"; "" ]);

  print_endline " -- 闭包捕获外层变量 --";
  check "keep_long 2 [...]" s_sl [ "abc"; "abcd" ] (fun () ->
      keep_long 2 [ "a"; "abc"; "ab"; "abcd" ]);
  check "keep_long 0 [\"\";\"a\"]" s_sl [ "a" ] (fun () -> keep_long 0 [ ""; "a" ]);
  check "shift 10 [1;2;3]" s_il [ 11; 12; 13 ] (fun () -> shift 10 [ 1; 2; 3 ]);
  check "shift (-1) [1;2]" s_il [ 0; 1 ] (fun () -> shift (-1) [ 1; 2 ]);

  print_endline " -- 自己写高阶函数 --";
  check "count_matching (> 2) [1;2;3;4]" si 2 (fun () ->
      count_matching (fun x -> x > 2) [ 1; 2; 3; 4 ]);
  check "count_matching (<> \"\") [\"a\";\"\";\"b\"]" si 2 (fun () ->
      count_matching (fun s -> s <> "") [ "a"; ""; "b" ]);
  check "count_matching 全不满足" si 0 (fun () -> count_matching (fun x -> x > 100) [ 1; 2 ]);

  print_endline " -- 组合 --";
  check "pos_doubled [3;-1;0;5]" s_il [ 6; 10 ] (fun () -> pos_doubled [ 3; -1; 0; 5 ]);
  check "pos_doubled [-2;-3]" s_il [] (fun () -> pos_doubled [ -2; -3 ])
