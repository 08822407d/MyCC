(* ex09_option — option：把「可能没有」写进类型里
   ------------------------------------------------------------------
   只改下面「你的代码」那一段，把 failwith 换成真正的实现。
   分隔线以下是自测代码，别改。

   你只需要三样东西（ex04 里拆 shape 的动作，换个构造器名而已）：

     Some x        有值
     None          没有

     match o with
     | Some v -> ...
     | None   -> ...

   ⛔ 这题【不用】 try / with，也【不用】自己定义类型。
      前两部分是「消费 option」，第三部分是「生产 option」。
   ------------------------------------------------------------------ *)

(* ======================= 你的代码（改这里） ======================= *)

(* ─────────── 第一部分：把 ex05/ex08 的异常版重写一遍 ─────────── *)

(* TODO 1：找出第一个长度 > 3 的字符串；一个都没有就返回 "无"。
   例：first_long ["ab"; "abcd"; "xyz"]  应得到  "abcd"
       first_long ["ab"; "xyz"]          应得到  "无"

   你在 ex08 里写的是：
     try List.find (fun s -> String.length s > 3) lst with Not_found -> "无"

   现在用 List.find_opt 重写。
     List.find_opt : ('a -> bool) -> 'a list -> 'a option *)
let first_long (lst : string list) : string =
  match List.find_opt (fun s -> String.length s > 3) lst with Some s -> s | None -> "无"

(* TODO 2：把字符串转成整数，转不了就返回默认值 d。
   例：to_int_or 0 "42"    应得到  42
       to_int_or 0 "abc"   应得到  0
       to_int_or (-1) "0"  应得到  0        ← 注意这条：0 是【成功】，不是失败

   你在 ex05 里写的是：
     try int_of_string s with Failure _ -> d

   现在用 int_of_string_opt 重写。
     int_of_string_opt : string -> int option *)
let to_int_or (d : int) (s : string) : int =
  match int_of_string_opt s with Some n -> n | None -> d

(* TODO 3：取第 n 个元素，取不到就返回默认值 d。
   例：nth_or 0 [10; 20; 30] 1     应得到  20
       nth_or (-1) [10] 99         应得到  -1
       nth_or (-1) [10] (-5)       应得到  -1

   你在 ex05 里写的是【两条 with 分支】（Failure 和 Invalid_argument）。
     List.nth_opt : 'a list -> int -> 'a option

   ⚠️⚠️ 注意一个刻意的设计：nth_opt 只把「表太短」变成 None，
        【下标为负数时它仍然抛 Invalid_argument】（实测）。
        因为那两件事性质不同 ——
          表太短   = 正常情况，调用方本来就该考虑「可能没有」  → option
          下标为负 = 调用方用错了，参数根本没有意义            → 异常
        所以这题不测负数下标。这个分工以后专门讲。 *)
let nth_or (d : 'a) (lst : 'a list) (n : int) : 'a =
  match List.nth_opt lst n with Some k -> k | None -> d

(* ─────────── 第二部分：只消费，不给默认值 ─────────── *)

(* TODO 4：把一个 int option 说成人话。
   例：describe (Some 5)  应得到  "有:5"
       describe None      应得到  "没有"

   ⚠️ 两支的类型必须一致（都是 string），和 ex05 的 classify 同一条规则。 *)
let describe (o : int option) : string =
  match o with Some n -> "有:" ^ string_of_int n | None -> "没有"

(* TODO 5：两个都有值才相加，否则没有结果。
   例：add_opts (Some 3) (Some 4)  应得到  Some 7
       add_opts (Some 3) None      应得到  None
       add_opts None None          应得到  None

   ⚠️ 这题要同时看两个 option。提示：可以用【元组模式】一次匹配两个（知识点 9.8）：
        match a, b with
        | Some x, Some y -> ...
        | _ -> ...
   ⚠️ 返回类型是 int option —— 所以你得【自己造】一个 Some 出来。 *)
let add_opts (a : int option) (b : int option) : int option =
  match (a, b) with Some x, Some y -> Some (x + y) | _ -> None

(* ─────────── 第三部分：生产 option ─────────── *)

(* TODO 6：安全除法。除数为 0 时没有结果。
   例：safe_div 10 2  应得到  Some 5
       safe_div 10 0  应得到  None

   ⚠️ 对照 ex05 的 safe_div：那版除零返回 0，【把失败伪装成了一个正常的结果】。
      这版把「没有结果」如实写进了类型。 *)
let safe_div (a : int) (b : int) : int option =
  match b with 0 -> None | _ -> Some (a / b)

(* TODO 7：取表头；空表就没有结果。
   例：head_opt [10; 20]  应得到  Some 10
       head_opt []        应得到  None

   ⚠️ 对照 ex05 的 head_or：那版要调用方先给一个默认值，
      这版把「有没有」交还给调用方自己决定。
   提示：直接对 lst 做 match（[] 和 x :: _ 两支）。 *)
let head_opt (lst : 'a list) : 'a option = match lst with [] -> None | x :: _ -> Some x
(* ===================== 分隔线以下别改 ===================== *)

let check name to_s expected thunk =
  match thunk () with
  | actual ->
      if actual = expected then Printf.printf "  [OK] %s\n" name
      else Printf.printf "  [XX] %s -> 期望 %s，实际 %s\n" name (to_s expected) (to_s actual)
  | exception e -> Printf.printf "  [--] %s -> 还没做（%s）\n" name (Printexc.to_string e)

let si = string_of_int
let ss (s : string) = s
let s_io = function Some n -> "Some " ^ string_of_int n | None -> "None"

let () =
  print_endline "ex09_option 自测:";

  print_endline " -- 重写异常版 --";
  check "first_long [ab;abcd;xyz]" ss "abcd" (fun () ->
      first_long [ "ab"; "abcd"; "xyz" ]);
  check "first_long [ab;xyz]" ss "无" (fun () -> first_long [ "ab"; "xyz" ]);
  check "to_int_or 0 \"42\"" si 42 (fun () -> to_int_or 0 "42");
  check "to_int_or 0 \"abc\"" si 0 (fun () -> to_int_or 0 "abc");
  check "to_int_or (-1) \"0\"  [0 是成功]" si 0 (fun () -> to_int_or (-1) "0");
  check "nth_or 0 [10;20;30] 1" si 20 (fun () -> nth_or 0 [ 10; 20; 30 ] 1);
  check "nth_or (-1) [10] 99" si (-1) (fun () -> nth_or (-1) [ 10 ] 99);
  check "nth_or \"?\" [a;b] 5" ss "?" (fun () -> nth_or "?" [ "a"; "b" ] 5);

  print_endline " -- 只消费 --";
  check "describe (Some 5)" ss "有:5" (fun () -> describe (Some 5));
  check "describe None" ss "没有" (fun () -> describe None);
  check "add_opts (Some 3) (Some 4)" s_io (Some 7) (fun () -> add_opts (Some 3) (Some 4));
  check "add_opts (Some 3) None" s_io None (fun () -> add_opts (Some 3) None);
  check "add_opts None (Some 4)" s_io None (fun () -> add_opts None (Some 4));
  check "add_opts None None" s_io None (fun () -> add_opts None None);

  print_endline " -- 生产 option --";
  check "safe_div 10 2" s_io (Some 5) (fun () -> safe_div 10 2);
  check "safe_div 10 0" s_io None (fun () -> safe_div 10 0);
  check "head_opt [10;20]" s_io (Some 10) (fun () -> head_opt [ 10; 20 ]);
  check "head_opt []" s_io None (fun () -> head_opt [])
