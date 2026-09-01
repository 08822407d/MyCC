# ex10_type_and 参考答案

> 自己没试过之前别看。

```ocaml
(* TODO 1 *)
let entry_name (e : entry) : string =
  match e with
  | File (n, _) -> n
  | Folder f -> f.name

(* TODO 2 *)
let rec size_entry (e : entry) : int =
  match e with
  | File (_, sz) -> sz
  | Folder f -> size_folder f

and size_folder (f : folder) : int =
  List.fold_left (fun acc e -> acc + size_entry e) 0 f.items

(* TODO 3 *)
let rec count_entry (e : entry) : int =
  match e with
  | File _ -> 1
  | Folder f -> count_folder f

and count_folder (f : folder) : int =
  List.fold_left (fun acc e -> acc + count_entry e) 0 f.items

(* TODO 4 *)
let rec depth_entry (e : entry) : int =
  match e with
  | File _ -> 0
  | Folder f -> depth_folder f

and depth_folder (f : folder) : int =
  1 + List.fold_left (fun acc e -> max acc (depth_entry e)) 0 f.items

(* TODO 5 *)
let rec names_entry (e : entry) : string list =
  match e with
  | File (n, _) -> [ n ]
  | Folder f -> names_folder f

and names_folder (f : folder) : string list =
  List.fold_right (fun e acc -> names_entry e @ acc) f.items []
```

## 几处值得说的

**TODO 2/3/5 是同一个骨架**，只有「一个 File 贡献什么」和「怎么并」两处不同：

| | File 贡献 | 怎么并 | 起点 |
|---|---|---|---|
| size | `sz` | `+` | `0` |
| count | `1` | `+` | `0` |
| depth | `0` | `max` | `0`，最后整体 `+1` |
| names | `[n]` | `@` | `[]` |

**TODO 4 的 `1 +` 在括号外面**：先求出「里面最深的」，再给自己这一层加 1。
空表时 `fold_left` 直接返回起点 `0`，于是空文件夹得 `1`，正好对上规矩。

**TODO 5 用 `fold_right` 是为了保住顺序**。用 `fold_left` 也行，但要么最后 `List.rev`，
要么把 `acc @ names_entry e` 写成左边接右边（能对，但每步都从头走一遍 `acc`，更慢）。
