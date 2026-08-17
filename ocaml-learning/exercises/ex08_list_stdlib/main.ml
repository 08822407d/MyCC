(* ex08_list_stdlib — List 模块常用函数
   ------------------------------------------------------------------
   这题不给 match 骨架了 —— 每道题都是【一行】，直接调标准库函数。
   考的是「想干这件事该拿哪个函数」，不是算法。

   只改下面「你的代码」那一段，把 failwith 换成真正的实现。
   分隔线以下是自测代码，别动。
   题目和提示见同目录的 README.md。
   写完跟 Claude 说一声（"好了" / "跑一下"）。

   ⛔ 这题【不用】 option（那块你要求推迟了），所以第 8 题用 try ... with 接异常。
   ------------------------------------------------------------------ *)

(* ======================= 你的代码（改这里） ======================= *)

(* TODO 1：用 List.iter 把所有元素累加起来。
   例：sum_via_iter [1; 2; 3]  应得到  6

   ⚠️ 这题【必须用 List.iter】，不许用 fold —— 目的是体会
      「iter 返回 unit，所以要攒结果就得配 ref」。
   骨架给了 ref 和最后的 !acc，你只写中间那一句。 *)
let sum_via_iter (lst : int list) : int =
  let acc = ref 0 in
  List.iter (fun x -> acc := x + !acc) lst;
  !acc

(* TODO 2：表里有没有负数？
   例：has_negative [1; -2; 3]  应得到  true
       has_negative [1; 2]      应得到  false *)
let has_negative (lst : int list) : bool = List.exists (fun x -> x < 0) lst

(* TODO 3：是不是所有元素都大于 0？
   例：all_positive [1; 2]   应得到  true
       all_positive [1; 0]   应得到  false
       all_positive []       应得到  true   （空表：没有反例，所以成立）

   ⚠️ 和 TODO 2 用的是一对兄弟函数，别搞混。 *)
let all_positive (lst : int list) : bool = List.for_all (fun x -> x > 0) lst

(* TODO 4：表里含不含 "hello" 这个字符串？
   例：contains_hello ["hi"; "hello"]  应得到  true

   提示：这题不需要你写谓词，有个函数直接收「值」。 *)
let contains_hello (lst : string list) : bool = List.mem "hello" lst

(* TODO 5：从大到小排序。
   例：sort_desc [3; 1; 2]  应得到  [3; 2; 1]

   提示：List.sort 要一个 comparator —— 就是 C 里 qsort 那个第四参数。
        升序是 compare，降序把两个参数掉个个儿。 *)
let sort_desc (lst : int list) : int list = List.sort compare lst

(* TODO 6：一刀两断，返回 (偶数们, 奇数们)。
   例：split_evens [1; 2; 3; 4]  应得到  ([2; 4], [1; 3])

   ⚠️ 返回类型是【元组】，有个函数一次就能给你两张表。 *)
let split_evens (lst : int list) : int list * int list = List.partition (fun x -> x mod 2 = 0) lst

(* TODO 7：给每个元素加上下标前缀。
   例：numbered ["a"; "b"]  应得到  ["0:a"; "1:b"]

   提示：普通 map 拿不到下标，有个带 i 的版本。字符串拼接用 ^ *)
let numbered (lst : string list) : string list = List.mapi (fun i x -> string_of_int i ^ ":" ^ x) lst

(* TODO 8：找出第一个长度 > 3 的字符串；一个都没有就返回 "无"。
   例：first_long ["ab"; "abcd"; "xyz"]  应得到  "abcd"
       first_long ["ab"; "xyz"]          应得到  "无"

   ⚠️ List.find 找不到时【抛 Not_found】（B3 学过的那个）。
      骨架给了 try 的形状，两处都要你填。 *)
let first_long (lst : string list) : string =
  try List.find (fun s -> String.length s > 3) lst with Not_found -> "无"

(* ===================== 分隔线以下别改 ===================== *)

let check name to_s expected thunk =
  match thunk () with
  | actual ->
      if actual = expected then Printf.printf "  [OK] %s\n" name
      else Printf.printf "  [XX] %s -> 期望 %s，实际 %s\n" name (to_s expected) (to_s actual)
  | exception e -> Printf.printf "  [--] %s -> 还没做（%s）\n" name (Printexc.to_string e)

let si = string_of_int
let sb = string_of_bool
let ss (s : string) = s
let sl lst = "[" ^ String.concat "; " (List.map string_of_int lst) ^ "]"
let ssl lst = "[" ^ String.concat "; " lst ^ "]"
let sp (a, b) = "(" ^ sl a ^ ", " ^ sl b ^ ")"

let () =
  print_endline "ex08_list_stdlib 自测:";
  check "sum_via_iter [1;2;3]" si 6 (fun () -> sum_via_iter [ 1; 2; 3 ]);
  check "sum_via_iter []" si 0 (fun () -> sum_via_iter []);
  check "has_negative [1;-2;3]" sb true (fun () -> has_negative [ 1; -2; 3 ]);
  check "has_negative [1;2]" sb false (fun () -> has_negative [ 1; 2 ]);
  check "all_positive [1;2]" sb true (fun () -> all_positive [ 1; 2 ]);
  check "all_positive [1;0]" sb false (fun () -> all_positive [ 1; 0 ]);
  check "all_positive []  [空表为真]" sb true (fun () -> all_positive []);
  check "contains_hello [hi;hello]" sb true (fun () -> contains_hello [ "hi"; "hello" ]);
  check "contains_hello [hi]" sb false (fun () -> contains_hello [ "hi" ]);
  check "sort_desc [3;1;2]" sl [ 3; 2; 1 ] (fun () -> sort_desc [ 3; 1; 2 ]);
  check "sort_desc []" sl [] (fun () -> sort_desc []);
  check "split_evens [1;2;3;4]" sp ([ 2; 4 ], [ 1; 3 ]) (fun () -> split_evens [ 1; 2; 3; 4 ]);
  check "numbered [a;b]" ssl [ "0:a"; "1:b" ] (fun () -> numbered [ "a"; "b" ]);
  check "numbered []" ssl [] (fun () -> numbered []);
  check "first_long [ab;abcd;xyz]" ss "abcd" (fun () -> first_long [ "ab"; "abcd"; "xyz" ]);
  check "first_long [ab;xyz]  [找不到]" ss "无" (fun () -> first_long [ "ab"; "xyz" ])
