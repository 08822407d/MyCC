(* main.ml — token 转储 CLI（决策 007/008）。
   默认输出：每 token 一行的原始拼写——T2 往返测试直接拿它喂 gcc。
   -l：每行前加映射后的位置（原始文件:行:列，系统头区间加标注）。 *)

let () =
  let with_loc = ref false in
  let path_arg = ref None in
  let usage = "用法: main [-l] <file.i>" in
  Arg.parse
    [ "-l", Arg.Set with_loc, " 每个 token 前打印映射后的位置" ]
    (fun s -> path_arg := Some s) usage;
  let path = match !path_arg with
    | Some p -> p
    | None -> prerr_endline usage; exit 2
  in
  let ic =
    try open_in_bin path
    with Sys_error e -> Printf.eprintf "打不开输入: %s\n" e; exit 2
  in
  let lexbuf = Lexing.from_channel ic in
  Lexing.set_filename lexbuf path;
  let lmap = Mycc_lexer.Line_map.create () in
  (try
     let rec loop () =
       match Mycc_lexer.Lexer.token lmap lexbuf with
       | Mycc_lexer.Tokens.EOF -> ()
       | tok ->
         if !with_loc then begin
           let p = Lexing.lexeme_start_p lexbuf in
           let file, line, sys =
             Mycc_lexer.Line_map.translate lmap
               ~phys_line:p.Lexing.pos_lnum ~fallback:path in
           Printf.printf "%s:%d:%d%s\t" file line
             (p.Lexing.pos_cnum - p.Lexing.pos_bol + 1)
             (if sys then " (系统头)" else "")
         end;
         print_endline (Mycc_lexer.Token_debug.to_spelling tok);
         loop ()
     in
     loop ()
   with Mycc_lexer.Lexer.Error { msg; file; line; col; phys_line } ->
     Printf.eprintf "%s:%d:%d: 词法错误: %s（%s 物理行 %d）\n"
       file line col msg path phys_line;
     exit 1);
  close_in ic
