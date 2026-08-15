(* ex07_fold — 用 fold 把一张表收拢成一个东西
   ------------------------------------------------------------------
   只改下面「你的代码」那一段，把 failwith 换成真正的实现。
   分隔线以下是自测代码，别改。

   ⛔ 这题只用 List.fold_left / List.fold_right / List.rev。
      【不要用】 map / filter（那是 ex06 的活）、不用 option、不用自己写 let rec。

   两个签名放这儿，做题时对照着看：
     List.fold_left  : ('acc -> 'a -> 'acc) -> 'acc    -> 'a list -> 'acc
     List.fold_right : ('a -> 'acc -> 'acc) -> 'a list -> 'acc    -> 'acc
   ⚠️ 两处参数顺序都是反的。记法：累加器靠近它「来的那一侧」。
   ------------------------------------------------------------------ *)

(* ======================= 你的代码（改这里） ======================= *)

(* ─────────── 第一部分：数值累加器（两个旋钮：怎么并 / 起点） ─────────── *)

(* TODO 1：把列表里所有数加起来。
   例：sum_list [1; 2; 3]  应得到  6
       sum_list []         应得到  0

   ⚠️ 这就是 ex03 的第 1 题。ex06 里它【故意缺席】，因为 map/filter 做不到收拢。
      现在补上。 *)
let sum_list (lst : int list) : int = List.fold_left (fun acc x -> acc + x) 0 lst

(* TODO 2：把列表里所有数乘起来。
   例：product [1; 2; 3; 4]  应得到  24
       product []            应得到  1

   ⚠️ 想清楚起点填什么 —— 空表的乘积是几？（和加法的 0 是同一类问题） *)
let product (lst : int list) : int = List.fold_left (fun acc x -> acc * x) 1 lst

(* TODO 3：数一数有几个偶数。
   例：count_evens [1; 2; 3; 4; 6]  应得到  3

   ⚠️ ex06 里你用的是 filter + length（两遍遍历）。
      这次用 fold 一遍走完，体会一下差别。 *)
let count_evens (lst : int list) : int = List.fold_left (fun acc x -> if x mod 2 = 0 then acc + 1 else acc) 0 lst

(* ─────────── 第二部分：累加器的类型 ≠ 元素的类型 ─────────── *)

(* TODO 4：所有字符串的总长度。
   例：total_length ["a"; "abc"; ""]  应得到  4
       total_length []                应得到  0

   ⚠️ 元素是 string，累加器是 int —— 签名里 'acc 和 'a 是两个独立的洞。 *)
let total_length (lst : string list) : int = List.fold_left (fun acc s -> acc + String.length s) 0 lst

(* TODO 5：是不是所有元素都大于 0。
   例：all_positive [3; 5; 1]   应得到  true
       all_positive [3; -5; 1]  应得到  false
       all_positive []          应得到  true      （空表算「都满足」）

   ⚠️ 累加器是 bool。想想起点填什么才能让空表得到 true。 *)
let all_positive (lst : int list) : bool = List.fold_left (fun acc x -> acc && (x > 0)) true lst

(* ─────────── 第三部分：累加器是一张表 ─────────── *)

(* TODO 6：把表反过来。
   例：my_rev [1; 2; 3]  应得到  [3; 2; 1]
       my_rev []         应得到  []

   ⚠️ 这题几乎白送 —— 我们刚讲过 fold_left + :: 天然产出倒序。
      起点填空表，每次把新元素挂到累加器头上。
   ⛔ 不许直接调用 List.rev（那是作弊）。 *)
let my_rev (lst : 'a list) : 'a list = List.fold_left (fun acc x -> x::acc) [] lst

(* TODO 7：把每个元素乘以 2，【保持原顺序】。
   例：double_all [1; 2; 3]  应得到  [2; 4; 6]

   ⚠️ 这题有两条路，随便选一条：
        (a) fold_left 造出倒序，最后 List.rev 纠正回来
        (b) fold_right 一步到位，不用 rev
      两条都写得出来的话，可以都试试，看哪个读起来更顺。
   ⛔ 不许用 List.map。 *)
let double_all (lst : int list) : int list = List.fold_right (fun x acc -> (x * 2)::acc) lst []

(* ─────────── 第四部分：综合 ─────────── *)

(* TODO 8：求最大值；空表就返回默认值 d。
   例：max_or 0 [3; 9; 2]     应得到  9
       max_or 0 []            应得到  0
       max_or "" ["b"; "a"]   应得到  "b"      （字符串也能比大小）

   ⚠️ 累加器就是「到目前为止见过的最大值」，起点就是 d。
   ⚠️ 元素类型是 'a —— 但 > 在 OCaml 里本来就是多态的（'a -> 'a -> bool），
      所以这题照样能写出来。 *)
let max_or (d : 'a) (lst : 'a list) : 'a = List.fold_left (fun acc x -> if x > acc then x else acc) d lst

(* ===================== 分隔线以下别改 ===================== *)

let check name to_s expected thunk =
  match thunk () with
  | actual ->
      if actual = expected then Printf.printf "  [OK] %s\n" name
      else Printf.printf "  [XX] %s -> 期望 %s，实际 %s\n" name (to_s expected) (to_s actual)
  | exception e -> Printf.printf "  [--] %s -> 还没做（%s）\n" name (Printexc.to_string e)

let si = string_of_int
let ss (s : string) = s
let sb = string_of_bool
let s_il l = "[" ^ String.concat "; " (List.map string_of_int l) ^ "]"

let () =
  print_endline "ex07_fold 自测:";

  print_endline " -- 数值累加器 --";
  check "sum_list [1;2;3]" si 6 (fun () -> sum_list [ 1; 2; 3 ]);
  check "sum_list []" si 0 (fun () -> sum_list []);
  check "product [1;2;3;4]" si 24 (fun () -> product [ 1; 2; 3; 4 ]);
  check "product []" si 1 (fun () -> product []);
  check "count_evens [1;2;3;4;6]" si 3 (fun () -> count_evens [ 1; 2; 3; 4; 6 ]);
  check "count_evens [1;3]" si 0 (fun () -> count_evens [ 1; 3 ]);

  print_endline " -- 累加器类型 ≠ 元素类型 --";
  check "total_length [\"a\";\"abc\";\"\"]" si 4 (fun () -> total_length [ "a"; "abc"; "" ]);
  check "total_length []" si 0 (fun () -> total_length []);
  check "all_positive [3;5;1]" sb true (fun () -> all_positive [ 3; 5; 1 ]);
  check "all_positive [3;-5;1]" sb false (fun () -> all_positive [ 3; -5; 1 ]);
  check "all_positive []" sb true (fun () -> all_positive []);

  print_endline " -- 累加器是一张表 --";
  check "my_rev [1;2;3]" s_il [ 3; 2; 1 ] (fun () -> my_rev [ 1; 2; 3 ]);
  check "my_rev []" s_il [] (fun () -> my_rev []);
  check "double_all [1;2;3]" s_il [ 2; 4; 6 ] (fun () -> double_all [ 1; 2; 3 ]);
  check "double_all []" s_il [] (fun () -> double_all []);

  print_endline " -- 综合 --";
  check "max_or 0 [3;9;2]" si 9 (fun () -> max_or 0 [ 3; 9; 2 ]);
  check "max_or 0 []" si 0 (fun () -> max_or 0 []);
  check "max_or 0 [-3;-9]" si 0 (fun () -> max_or 0 [ -3; -9 ]);
  check "max_or \"\" [\"b\";\"a\"]" ss "b" (fun () -> max_or "" [ "b"; "a" ])
