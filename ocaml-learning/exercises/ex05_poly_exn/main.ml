(* ex05_poly_exn — 类型变量 'a + 异常
   ------------------------------------------------------------------
   ⚠️ 和前两题一样：match / try 的骨架已经替你写好，你只填 -> 右边那一段。

   只改下面「你的代码」那一段，把 failwith 换成真正的实现。
   分隔线以下是自测代码，别动。
   题目和提示见同目录的 README.md。
   写完跟 Claude 说一声（"好了" / "跑一下"），它会自动构建运行并反馈。

   ⛔ 这题【不用】 option，也【不用】自己定义带参数的类型。
      只用你已经会的：match、递归、列表、try ... with。
   ------------------------------------------------------------------ *)

(* ======================= 你的代码（改这里） ======================= *)

(* ─────────────── 第一部分：类型变量 'a ─────────────── *)

(* TODO 1：交换二元组的两个分量。
   例：swap (1, "a")  应得到  ("a", 1)
       swap (1, 2)    应得到  (2, 1)

   'a 和 'b 是两个【不同名的洞】，所以它们可以不同、也可以相同
   —— 第二条测试就是专门验后面这半句的。

   提示：参数位置可以直接写元组模式，比如  let f (x, y) = ...
        这里给你标注了类型，你把函数体写出来就行。 *)
let swap (p : 'a * 'b) : 'b * 'a = let (a, b) = p in (b, a)

(* TODO 2：造一张有 n 个 x 的表。
   例：repeat 7 3     应得到  [7; 7; 7]
       repeat "ab" 2  应得到  ["ab"; "ab"]
       repeat 7 0     应得到  []

   ⚠️ 注意 x 的类型是 'a —— 你【不能】对它做任何事（不能加、不能比、不能打印），
      只能原样放进表里。这正是 'a 的含义。

   提示：递归。n <= 0 是基准情形。造表用 :: （ex03 练过）。 *)
let rec repeat (x : 'a) (n : int) : 'a list =
   if n <= 0 then []
   else x :: repeat x (n - 1)

(* TODO 3：取表头；表是空的就返回默认值 d。
   例：head_or 0 [10; 20]   应得到  10
       head_or 0 []         应得到  0
       head_or "-" ["hi"]   应得到  "hi"

   ⚠️ d 和表里的元素必须是同一个类型（签名里两个 'a 同名）——
      想想为什么必须这样：如果不是，返回值的类型就说不清了。 *)
let head_or (d : 'a) (lst : 'a list) : 'a =
  match lst with
  | [] -> d
  | x :: _ -> x

(* ─────────────── 第二部分：异常 ─────────────── *)

(* TODO 4：安全除法。除数为 0 时返回 0，不要让程序崩。
   例：safe_div 10 2  应得到  5
       safe_div 10 0  应得到  0

   骨架给了 try 的形状，两处都要你填：
     try 后面   —— 正常情况下要算什么
     -> 右面    —— 出事了返回什么 *)
let safe_div (a : int) (b : int) : int =
  try a / b with
  | Division_by_zero -> 0

(* TODO 5：把字符串转成整数，转不了就返回默认值 d。
   例：to_int_or 0 "42"    应得到  42
       to_int_or 0 "abc"   应得到  0
       to_int_or (-1) ""   应得到  -1

   提示：int_of_string "abc" 抛的是 Failure（前面实测过）。 *)
let to_int_or (d : int) (s : string) : int =
  try int_of_string s with
  | Failure _ -> d

(* TODO 6：取第 n 个元素，取不到就返回默认值 d。
   例：nth_or 0 [10; 20; 30] 1     应得到  20
       nth_or (-1) [10] 99         应得到  -1     （表太短）
       nth_or (-1) [10] (-5)       应得到  -1     （下标是负数）

   ⚠️ List.nth 在两种情况下抛【两个不同的异常】：
        表太短    -> Failure "nth"
        下标为负  -> Invalid_argument "List.nth"
      所以骨架给了两条分支，两条都要填（可以填一样的东西）。

   ⚠️ 这题的 d 和元素都是 'a —— 你的实现里不能对它们做任何类型相关的操作。 *)
let nth_or (d : 'a) (lst : 'a list) (n : int) : 'a =
  try List.nth lst n  with
  | Failure _ -> d
  | Invalid_argument _ -> d

(* TODO 7：跑一段可能出事的代码，用一句话描述结果。
   f 是一个「调用时才执行」的东西（ex02 的自测里见过这种写法）。

   期望的返回值：
     没出事，f () 得到 n  ->  "ok:" ^ string_of_int n     例："ok:5"
     Division_by_zero     ->  "除零"
     Failure msg          ->  "失败:" ^ msg               例："失败:boom"
     Not_found            ->  "没找到"
     其他任何异常          ->  "其他"

   ⚠️ 两个考点：
     ① try 的所有分支类型必须一致 —— 这里全都是 string，
        所以 try 后面那一段【不能】只写 f ()（那是 int），要转成 string。
     ② 兜底的 _ 必须放最后。骨架里已经放好了，体会一下为什么不能往前挪。 *)
let classify (f : unit -> int) : string =
  try string_of_int (f ()) with
  | Division_by_zero -> "除零"
  | Failure msg -> "失败:" ^ msg
  | Not_found -> "没找到"
  | _ -> "其他"

(* ===================== 分隔线以下别改 ===================== *)

let check name to_s expected thunk =
  match thunk () with
  | actual ->
      if actual = expected then Printf.printf "  [OK] %s\n" name
      else Printf.printf "  [XX] %s -> 期望 %s，实际 %s\n" name (to_s expected) (to_s actual)
  | exception e -> Printf.printf "  [--] %s -> 还没做（%s）\n" name (Printexc.to_string e)

let si = string_of_int
let ss (s : string) = s
let s_si (s, i) = Printf.sprintf "(%S, %d)" s i
let s_ii (a, b) = Printf.sprintf "(%d, %d)" a b
let s_il l = "[" ^ String.concat "; " (List.map string_of_int l) ^ "]"
let s_sl l = "[" ^ String.concat "; " (List.map (Printf.sprintf "%S") l) ^ "]"

let () =
  print_endline "ex05_poly_exn 自测:";

  print_endline " -- 第一部分：'a --";
  check "swap (1, \"a\")" s_si ("a", 1) (fun () -> swap (1, "a"));
  check "swap (1, 2)  ['a 和 'b 同类型也合法]" s_ii (2, 1) (fun () -> swap (1, 2));
  check "repeat 7 3" s_il [ 7; 7; 7 ] (fun () -> repeat 7 3);
  check "repeat 7 0" s_il [] (fun () -> repeat 7 0);
  check "repeat \"ab\" 2" s_sl [ "ab"; "ab" ] (fun () -> repeat "ab" 2);
  check "head_or 0 [10; 20]" si 10 (fun () -> head_or 0 [ 10; 20 ]);
  check "head_or 0 []" si 0 (fun () -> head_or 0 []);
  check "head_or \"-\" [\"hi\"]" ss "hi" (fun () -> head_or "-" [ "hi" ]);

  print_endline " -- 第二部分：异常 --";
  check "safe_div 10 2" si 5 (fun () -> safe_div 10 2);
  check "safe_div 10 0" si 0 (fun () -> safe_div 10 0);
  check "to_int_or 0 \"42\"" si 42 (fun () -> to_int_or 0 "42");
  check "to_int_or 0 \"abc\"" si 0 (fun () -> to_int_or 0 "abc");
  check "to_int_or (-1) \"\"" si (-1) (fun () -> to_int_or (-1) "");
  check "nth_or 0 [10;20;30] 1" si 20 (fun () -> nth_or 0 [ 10; 20; 30 ] 1);
  check "nth_or (-1) [10] 99  [表太短]" si (-1) (fun () -> nth_or (-1) [ 10 ] 99);
  check "nth_or (-1) [10] (-5)  [下标为负]" si (-1) (fun () -> nth_or (-1) [ 10 ] (-5));
  check "nth_or \"?\" [\"a\";\"b\"] 5" ss "?" (fun () -> nth_or "?" [ "a"; "b" ] 5);
  check "classify 正常" ss "ok:5" (fun () -> classify (fun () -> 10 / 2));
  check "classify 除零" ss "除零" (fun () -> classify (fun () -> 10 / 0));
  check "classify failwith" ss "失败:boom" (fun () -> classify (fun () -> failwith "boom"));
  check "classify Not_found" ss "没找到" (fun () -> classify (fun () -> raise Not_found));
  check "classify 其他" ss "其他" (fun () -> classify (fun () -> raise Exit))
