(* ex10_type_and — 相互引用的类型 + 相互递归的函数
   ------------------------------------------------------------------
   只改下面「你的代码」那一段，把 failwith 换成真正的实现。
   分隔线以下是自测代码，别改。

   这一题的新东西只有一个：and。
   其余全是学过的：变体、记录、列表、match、fold。

   ⛔ 不需要 option、不需要异常、不需要 ref。
   ------------------------------------------------------------------ *)

(* ============ 下面这两个类型是给好的，别改，但要看懂 ============ *)

(* 一个「条目」要么是文件（文件名 + 字节数），要么是一个子文件夹。
   一个「文件夹」有名字，里面装着一串条目。
   两个类型互相提到对方 —— 所以第二个用 and 接上，不能另起一个 type。 *)

type entry =
  | File of string * int (* 文件名, 字节数 *)
  | Folder of folder

and folder = { name : string; items : entry list }

(* 长这样：

   proj/
     README.md      120
     src/
       main.ml      300
       dune          40
     empty/
     LICENSE         60
*)

(* ======================= 你的代码（改这里） ======================= *)

(* ─────────── 第一部分：热身，不用递归 ─────────── *)

(* TODO 1：取出一个条目的名字。
   文件就是它的文件名，文件夹就是它的文件夹名。

   例：entry_name (File ("a.txt", 10))                       应得到  "a.txt"
       entry_name (Folder { name = "src"; items = [] })      应得到  "src"

   ⚠️ 只考 match 两个分支 + 记录取字段（f.name）。 *)
let entry_name (e : entry) : string =
  match e with
  | File (name, _) -> name
  | Folder f -> f.name

(* ─────────── 第二部分：相互递归（本题的重点） ─────────── *)

(* 下面每道题都给了【两个】函数，用 and 连着：
     一个处理「一个条目」，一个处理「一个文件夹」。
   它们互相调用 —— 这正是 and 存在的理由。

   套路是固定的，第一道想通了，后面两道是同一个形状。 *)

(* TODO 2：算总字节数（把所有文件的字节数加起来，子文件夹里的也要算）。

   例：total_size_folder demo   应得到  520      （120 + 300 + 40 + 0 + 60）
       total_size_folder empty  应得到  0

   提示：
     - size_entry 遇到 File 就返回它的字节数；遇到 Folder 就把活交给 size_folder
     - size_folder 要把 f.items 这张表收拢成一个数 —— 你有 List.fold_left *)
let rec size_entry (e : entry) : int =
  match e with
  | File (_, s) -> s
  | Folder f -> size_folder f
    
and size_folder (f : folder) : int =
  List.fold_left (fun acc e -> acc + size_entry e) 0 f.items

(* TODO 3：数一共有多少个文件（文件夹本身不算）。

   例：count_files_folder demo   应得到  4
       count_files_folder empty  应得到  0

   ⚠️ 和 TODO 2 是同一个形状，只是「每个 File 贡献多少」变了。 *)
let rec count_entry (e : entry) : int =
  match e with
  | File _ -> 1
  | Folder f -> count_folder f

and count_folder (f : folder) : int =
  List.fold_left (fun acc e -> acc + count_entry e) 0 f.items

(* TODO 4：算文件夹的嵌套层数。规矩定死如下：
     - 一个 File 的层数是 0（文件不算一层）
     - 一个 Folder 的层数 = 它自己这一层(1) + 里面最深的那个条目的层数
     - 空文件夹的层数是 1

   例：depth_folder empty  应得到  1        （empty/ 里什么都没有）
       depth_folder demo   应得到  2        （proj/ 里最深的是 src/）
       depth_folder deep   应得到  3        （a/b/c/x.txt）

   提示：
     - OCaml 有内置的 max : 'a -> 'a -> 'a，直接用
     - 「里面最深的那个」= 从 0 起步，用 fold_left 一路取 max *)
let rec depth_entry (e : entry) : int =
  match e with
  | File _ -> 0
  | Folder f -> depth_folder f
and depth_folder (f : folder) : int =
  1 + (List.fold_left (fun m e -> max m (depth_entry e)) 0 f.items)

(* ─────────── 第三部分：结果是一张表 ─────────── *)

(* TODO 5：把所有文件名收集成一张表，顺序按上面画的那棵树从上往下。

   例：names_folder demo   应得到  ["README.md"; "main.ml"; "dune"; "LICENSE"]
       names_folder empty  应得到  []

   提示：
     - names_entry 碰到 File 就返回【只有一个元素的表】，碰到 Folder 就转交
     - names_folder 要把一堆小表接成一张大表 —— @ 能把两张表接起来
     - 想不出来就退回 fold_left + List.rev，或者试试 fold_right *)
let rec names_entry (e : entry) : string list =
  match e with
  | File (name, _) -> [name]
  | Folder f -> names_folder f
and names_folder (f : folder) : string list =
  List.fold_left (fun acc e -> acc @ (names_entry e)) [] f.items

(* ===================== 分隔线以下别改 ===================== *)

let demo =
  {
    name = "proj";
    items =
      [
        File ("README.md", 120);
        Folder
          { name = "src"; items = [ File ("main.ml", 300); File ("dune", 40) ] };
        Folder { name = "empty"; items = [] };
        File ("LICENSE", 60);
      ];
  }

let empty = { name = "empty"; items = [] }

let deep =
  {
    name = "a";
    items =
      [
        Folder
          {
            name = "b";
            items = [ Folder { name = "c"; items = [ File ("x.txt", 1) ] } ];
          };
      ];
  }

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
let ss (s : string) = s
let s_sl l = "[" ^ String.concat "; " l ^ "]"

let () =
  print_endline "ex10_type_and 自测:";

  print_endline " -- 热身 --";
  check "entry_name (File)" ss "a.txt" (fun () -> entry_name (File ("a.txt", 10)));
  check "entry_name (Folder)" ss "src" (fun () ->
      entry_name (Folder { name = "src"; items = [] }));

  print_endline " -- 总字节数 --";
  check "size_folder demo" si 520 (fun () -> size_folder demo);
  check "size_folder empty" si 0 (fun () -> size_folder empty);
  check "size_entry (File)" si 7 (fun () -> size_entry (File ("k", 7)));
  check "size_entry (Folder demo)" si 520 (fun () -> size_entry (Folder demo));

  print_endline " -- 文件个数 --";
  check "count_folder demo" si 4 (fun () -> count_folder demo);
  check "count_folder empty" si 0 (fun () -> count_folder empty);
  check "count_folder deep" si 1 (fun () -> count_folder deep);

  print_endline " -- 嵌套层数 --";
  check "depth_folder empty" si 1 (fun () -> depth_folder empty);
  check "depth_folder demo" si 2 (fun () -> depth_folder demo);
  check "depth_folder deep" si 3 (fun () -> depth_folder deep);
  check "depth_entry (File)" si 0 (fun () -> depth_entry (File ("k", 7)));

  print_endline " -- 收集文件名 --";
  check "names_folder demo" s_sl
    [ "README.md"; "main.ml"; "dune"; "LICENSE" ]
    (fun () -> names_folder demo);
  check "names_folder empty" s_sl [] (fun () -> names_folder empty);
  check "names_folder deep" s_sl [ "x.txt" ] (fun () -> names_folder deep)
