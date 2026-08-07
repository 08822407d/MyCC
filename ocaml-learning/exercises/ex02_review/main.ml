(* ex02_review — 综合复习：Printf / 类型转换 / 分号与 unit / ref
   ------------------------------------------------------------------
   只改下面「你的代码」那一段，把 failwith 换成真正的实现。
   分隔线以下是自测代码，别动。
   题目和提示见同目录的 README.md。
   写完跟 Claude 说一声（"好了" / "跑一下"），它会自动构建运行并反馈。
   ------------------------------------------------------------------ *)

(* ======================= 你的代码（改这里） ======================= *)

(* TODO 1：把 name 和 n 拼成 "name = n" 这样的字符串。
   例：describe "age" 3  应得到  "age = 3"
   提示：用 Printf.sprintf，注意它和 printf 的返回类型不一样。 *)
let describe (name : string) (n : int) : string = Printf.sprintf "%s = %d" name n

(* TODO 2：求 a 和 b 的平均值，结果取整。
   例：avg_trunc 3 4  应得到  3
   注意：整数除法会先丢掉小数，所以要先进浮点世界算完再回来。
   ⚠️ 负数那条测试是故意的，想清楚 int_of_float 到底怎么取整。 *)
let avg_trunc (a : int) (b : int) : int = int_of_float (float_of_int (a + b) /. 2.)

(* TODO 3：把 r 里的数加 1，加两次，然后返回最终的值。
   例：r 里原本是 5，调用后 r 里是 7，函数返回 7
   提示：需要连续做三件事，想想用什么把它们串起来。 *)
let bump_twice (r : int ref) : int =
  r := !r + 1;
  r := !r + 1;
  !r

(* TODO 4：交换 a 和 b 两个盒子里的内容。
   例：a 里是 1、b 里是 2，调用后 a 里是 2、b 里是 1
   提示：和 C 里交换两个变量一样，需要一个临时的地方存一下。 *)
let swap (a : int ref) (b : int ref) : unit =
  let tmp = !a in
  a := !b;
  b := tmp

(* ===================== 分隔线以下别改 ===================== *)

let check name to_s expected thunk =
  match thunk () with
  | actual ->
      if actual = expected then Printf.printf "  [OK] %s\n" name
      else Printf.printf "  [XX] %s -> 期望 %s，实际 %s\n" name (to_s expected) (to_s actual)
  | exception e -> Printf.printf "  [--] %s -> 还没做（%s）\n" name (Printexc.to_string e)

let si = string_of_int
let ss s = s

let () =
  print_endline "ex02_review 自测:";
  check "describe \"age\" 3" ss "age = 3" (fun () -> describe "age" 3);
  check "describe \"count\" 0" ss "count = 0" (fun () -> describe "count" 0);
  check "avg_trunc 3 4" si 3 (fun () -> avg_trunc 3 4);
  check "avg_trunc (-3) (-4)" si (-3) (fun () -> avg_trunc (-3) (-4));
  check "bump_twice (ref 5)" si 7 (fun () -> bump_twice (ref 5));
  check "bump_twice (ref (-1))" si 1 (fun () -> bump_twice (ref (-1)));
  check "swap 1 2" ss "2,1" (fun () ->
      let a = ref 1 in
      let b = ref 2 in
      swap a b;
      Printf.sprintf "%d,%d" !a !b);
  check "swap 7 7" ss "7,7" (fun () ->
      let a = ref 7 in
      let b = ref 7 in
      swap a b;
      Printf.sprintf "%d,%d" !a !b)
