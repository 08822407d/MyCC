(* ex03_list_recursion — 用递归处理列表
   ------------------------------------------------------------------
   ⚠️ 这一题的 match 骨架已经替你写好了，你只需要填 -> 右边那一段。
      不用自己发明模式，专心想「递归怎么写」。

   只改下面「你的代码」那一段，把 failwith 换成真正的实现。
   分隔线以下是自测代码，别动。
   题目和提示见同目录的 README.md。
   写完跟 Claude 说一声（"好了" / "跑一下"），它会自动构建运行并反馈。
   ------------------------------------------------------------------ *)

(* ======================= 你的代码（改这里） ======================= *)

(* TODO 1：把列表里所有数加起来。
   例：sum_list [1; 2; 3]  应得到  6
       sum_list []         应得到  0

   两条分支各填一个表达式：
     [] 那条    —— 空表的和是多少？（想想加法的"什么都没加"是几）
     x :: rest  —— x 是头（一个 int），rest 是尾（还是一张表）。
                   已知 sum_list rest 能算出尾巴的和，那整张表的和怎么拼？ *)
let rec sum_list (lst : int list) : int =
  match lst with
  | [] -> 0
  | x :: rest -> x + sum_list rest

(* TODO 2：数一数列表里有几个偶数。
   例：count_evens [1; 2; 3; 4]  应得到  2
       count_evens [1; 3]        应得到  0

   提示：判断偶数用 x mod 2 = 0（mod 不带点，只吃 int；判等用一个等号）。
        递归情形里要根据 x 是不是偶数决定加 1 还是加 0。 *)
let rec count_evens (lst : int list) : int =
  match lst with
  | [] -> 0
  | x :: rest -> (if x mod 2 = 0 then 1 else 0) + count_evens rest

(* TODO 3：把每个元素乘以 2，返回一张新表（原表不动）。
   例：double_all [1; 2; 3]  应得到  [2; 4; 6]
       double_all []         应得到  []

   ⚠️ 这题的返回值是 int list，不是 int。
   提示：递归情形要「造」一张表出来 —— 造表的工具你今天刚学过，就是 ::
        头是 x * 2，尾是「rest 处理完的结果」。 *)
let rec double_all (lst : int list) : int list =
  match lst with
  | [] -> []
  | x :: rest -> (x * 2) :: double_all rest

(* TODO 4：还是求和，但要写成尾递归（用累加器）。
   例：sum_tail [1; 2; 3]  应得到  6

   骨架已经搭好：外面是壳，里面 go 是真正干活的递归函数，
   最后一行 go 0 lst 把累加器的初始值 0 藏在了里面。

   ⚠️ 这题的考点全在基准情形：一路攒在 acc 里的东西，到头了要交出去。
      （回想 10.6 里你踩过的那个坑：基准情形返回 0 会让结果恒等于 0。）
   ⚠️ 递归情形必须是「最后一件事就是调用 go」，回来之后不能再做加工。 *)
let sum_tail (lst : int list) : int =
  let rec go (acc : int) (rest : int list) : int =
    match rest with
    | [] -> acc
    | x :: tl -> go (acc + x) tl
  in
  go 0 lst

(* ===================== 分隔线以下别改 ===================== *)

let check name to_s expected thunk =
  match thunk () with
  | actual ->
      if actual = expected then Printf.printf "  [OK] %s\n" name
      else Printf.printf "  [XX] %s -> 期望 %s，实际 %s\n" name (to_s expected) (to_s actual)
  | exception e -> Printf.printf "  [--] %s -> 还没做（%s）\n" name (Printexc.to_string e)

let si = string_of_int
let sl lst = "[" ^ String.concat "; " (List.map string_of_int lst) ^ "]"

let () =
  print_endline "ex03_list_recursion 自测:";
  check "sum_list [1; 2; 3]" si 6 (fun () -> sum_list [ 1; 2; 3 ]);
  check "sum_list []" si 0 (fun () -> sum_list []);
  check "sum_list [-5; 5; 7]" si 7 (fun () -> sum_list [ -5; 5; 7 ]);
  check "count_evens [1; 2; 3; 4]" si 2 (fun () -> count_evens [ 1; 2; 3; 4 ]);
  check "count_evens [1; 3]" si 0 (fun () -> count_evens [ 1; 3 ]);
  check "count_evens []" si 0 (fun () -> count_evens []);
  check "double_all [1; 2; 3]" sl [ 2; 4; 6 ] (fun () -> double_all [ 1; 2; 3 ]);
  check "double_all []" sl [] (fun () -> double_all []);
  check "sum_tail [1; 2; 3]" si 6 (fun () -> sum_tail [ 1; 2; 3 ]);
  check "sum_tail []" si 0 (fun () -> sum_tail []);
  (* 大输入的冒烟测试。
     ⚠️ 说清楚：这条测试**不能**证明你写的是尾递归。
     实测过，非尾递归写法喂一千万都不会溢出（OCaml 5 的主栈会自己长）。
     真要撞出 Stack overflow 得上亿级，那样光列表本身就要几个 GB。
     所以「是不是真的尾递归」由 Claude 读代码来判断。 *)
  check "sum_tail 一百万个 1" si 1_000_000
    (fun () -> sum_tail (List.init 1_000_000 (fun _ -> 1)))
