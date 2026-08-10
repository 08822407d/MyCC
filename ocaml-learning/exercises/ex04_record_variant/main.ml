(* ex04_record_variant — 记录 + 变体（ADT）的造与拆
   ------------------------------------------------------------------
   ⚠️ 和 ex03 一样：match 的骨架已经替你写好，你只填 -> 右边那一段。
      TODO 5 例外，那题要你自己造一个记录。

   只改下面「你的代码」那一段，把 failwith 换成真正的实现。
   分隔线以下是自测代码，别动。
   题目和提示见同目录的 README.md。
   写完跟 Claude 说一声（"好了" / "跑一下"），它会自动构建运行并反馈。
   ------------------------------------------------------------------ *)

(* ===== 类型定义（别改，题目就建立在这上面） ===== *)

type fabric = Linen | Cotton | Wool
type item = Shirt | Pants | Hat

(* 记录：既有款式，又有面料 *)
type project = { itm : item; fab : fabric }

(* 变体：三种形状，注意三个构造器带的数据个数不一样 *)
type shape =
  | Point                        (* 不带数据 *)
  | Circle of float              (* 带一个：半径 *)
  | Rect of float * float        (* 带两个：宽、高 *)

(* ======================= 你的代码（改这里） ======================= *)

(* TODO 1：把面料翻成字符串。
   Linen -> "亚麻"   Cotton -> "棉"   Wool -> "羊毛"

   这题只用到「分辨是哪一个构造器」，三个构造器都不带数据，
   所以每条分支直接写结果就行。 *)
let fabric_name (f : fabric) : string =
  match f with
  | Linen -> "亚麻"
  | Cotton -> "棉"
  | Wool -> "羊毛"

(* TODO 2：算面积。圆周率就用 3.14（不要用 Float.pi，测试是按 3.14 算的）。
   Point -> 0.       Circle r -> 3.14 * r * r      Rect (w, h) -> w * h

   ⚠️ 浮点乘法是 *. 不是 *
   这题三条分支正好覆盖「带 0 个 / 1 个 / 2 个数据」三种构造器。 *)
let area (s : shape) : float =
  match s with
  | Point -> 0.
  | Circle r -> r *. r *. 3.14
  | Rect (w, h) -> w *. h

(* TODO 3：只说它是哪一类，不关心里面的数。
   Point -> "点"     Circle _ -> "圆"     Rect _ -> "矩形"

   注意骨架里用的是 _ ——「这个位置我不要」。
   你只要填三个字符串，体会一下和 TODO 2 的区别。 *)
let kind (s : shape) : string =
  match s with
  | Point -> "点"
  | Circle _ -> "圆"
  | Rect _ -> "矩形"

(* TODO 4：算一件作品要多少钱。
   规则：底价按款式定，再乘面料系数，结果取整。
     款式底价： Shirt -> 100    Pants -> 150   Hat -> 60
     面料系数： Linen -> 1.5    Cotton -> 1.0  Wool -> 2.0

   骨架给了两个内部函数的壳，你把三条分支各自填掉，
   最后一行 in 后面的表达式也要你写（提示：底价是 int，系数是 float，
   两个不能直接相乘 —— 知识点 5）。 *)
let cost (p : project) : int =
  let base =
    match p.itm with
    | Shirt -> 100
    | Pants -> 150
    | Hat -> 60
  in
  let factor =
    match p.fab with
    | Linen -> 1.5
    | Cotton -> 1.0
    | Wool -> 2.0
  in
  int_of_float (factor *. float_of_int base)

(* TODO 5：换面料 —— 返回一件款式不变、面料换成 new_fab 的新作品。
   ⚠️ 原来那件 p 必须原封不动（记录是不可变的）。
   提示：今天讲过一个专门干这个的写法，比重新写全部字段省事。 *)
let rewrap (p : project) (new_fab : fabric) : project = { p with fab = new_fab }

(* ===================== 分隔线以下别改 ===================== *)

let check name to_s expected thunk =
  match thunk () with
  | actual ->
      if actual = expected then Printf.printf "  [OK] %s\n" name
      else Printf.printf "  [XX] %s -> 期望 %s，实际 %s\n" name (to_s expected) (to_s actual)
  | exception e -> Printf.printf "  [--] %s -> 还没做（%s）\n" name (Printexc.to_string e)

let si = string_of_int
let sf = string_of_float
let ss (s : string) = s

let show_fab = function Linen -> "Linen" | Cotton -> "Cotton" | Wool -> "Wool"
let show_itm = function Shirt -> "Shirt" | Pants -> "Pants" | Hat -> "Hat"
let sp p = Printf.sprintf "{itm = %s; fab = %s}" (show_itm p.itm) (show_fab p.fab)

let () =
  print_endline "ex04_record_variant 自测:";
  check "fabric_name Linen" ss "亚麻" (fun () -> fabric_name Linen);
  check "fabric_name Wool" ss "羊毛" (fun () -> fabric_name Wool);
  check "area Point" sf 0. (fun () -> area Point);
  check "area (Circle 2.)" sf 12.56 (fun () -> area (Circle 2.));
  check "area (Rect (3., 4.))" sf 12. (fun () -> area (Rect (3., 4.)));
  check "kind Point" ss "点" (fun () -> kind Point);
  check "kind (Circle 9.)" ss "圆" (fun () -> kind (Circle 9.));
  check "kind (Rect (1., 2.))" ss "矩形" (fun () -> kind (Rect (1., 2.)));
  check "cost 棉衬衫" si 100 (fun () -> cost { itm = Shirt; fab = Cotton });
  check "cost 羊毛裤" si 300 (fun () -> cost { itm = Pants; fab = Wool });
  check "cost 亚麻帽" si 90 (fun () -> cost { itm = Hat; fab = Linen });
  check "rewrap 换成 Wool" sp
    { itm = Shirt; fab = Wool }
    (fun () -> rewrap { itm = Shirt; fab = Cotton } Wool);
  (* 这条专门验「原件没被改动」 *)
  check "rewrap 之后原件不变" sp
    { itm = Shirt; fab = Cotton }
    (fun () ->
      let p = { itm = Shirt; fab = Cotton } in
      let _ = rewrap p Wool in
      p)
