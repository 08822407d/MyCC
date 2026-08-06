(* ex01_int_float — 整数和浮点：两套运算符，没有隐式转换
   ------------------------------------------------------------------
   只改下面「你的代码」那一段，把 failwith 换成真正的实现。
   分隔线以下是自测代码，别动。
   题目和提示见同目录的 README.md。
   写完跟 Claude 说一声（"好了" / "跑一下"），它会自动构建运行并反馈。
   ------------------------------------------------------------------ *)

(* ======================= 你的代码（改这里） ======================= *)

(* TODO 1：返回 n 的两倍。 *)
let double_int (n : int) : int = 2 * n

(* TODO 2：返回 x 的一半。
   注意：整数用的那个除号在这里是编译不过的。 *)
let half_float (x : float) : float = x /. 2.

(* TODO 3：把整数 n 变成浮点，再和 x 相加。
   OCaml 不会替你做这个转换，得自己写出来。 *)
let add_int_float (n : int) (x : float) : float = float_of_int n +. x

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

let si = string_of_int
let sf = string_of_float

let () =
  print_endline "ex01_int_float 自测:";
  check "double_int 21" si 42 (fun () -> double_int 21);
  check "double_int (-3)" si (-6) (fun () -> double_int (-3));
  check "half_float 5.0" sf 2.5 (fun () -> half_float 5.0);
  check "half_float 1.0" sf 0.5 (fun () -> half_float 1.0);
  check "add_int_float 3 0.5" sf 3.5 (fun () -> add_int_float 3 0.5);
  check "add_int_float 0 2.25" sf 2.25 (fun () -> add_int_float 0 2.25)
