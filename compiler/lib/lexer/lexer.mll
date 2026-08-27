(* lexer.mll — C17 词法分析器本体。
   设计：compiler-roadmap/spec/lexer/DESIGN.md（决策 005–008）。
   输入契约：只认 gcc -E 产出的 .i；未预处理输入给人话诊断（DESIGN.md §2）。 *)

{
open Tokens

(* 词法错误：file/line 已经过行映射表翻译（决策 006）。
   col 是 .i 里的列号——宏展开过的行上不可信（决策 002 的已知代价）。 *)
type error_info = {
  msg : string;
  file : string;      (* 映射后的原始文件名 *)
  line : int;         (* 映射后的原始行号 *)
  col : int;
  phys_line : int;    (* .i 物理行号，可直接 sed -n 'Np' 定位 *)
}

exception Error of error_info

let error lmap lexbuf msg =
  let p = Lexing.lexeme_start_p lexbuf in
  let phys_line = p.Lexing.pos_lnum in
  let file, line, _sys =
    Line_map.translate lmap ~phys_line ~fallback:p.Lexing.pos_fname in
  raise (Error { msg; file; line;
                 col = p.Lexing.pos_cnum - p.Lexing.pos_bol + 1; phys_line })

let unpreprocessed lmap lexbuf what =
  error lmap lexbuf
    (Printf.sprintf "输入似乎未经预处理（%s），请先执行 gcc -E" what)

(* 44 个 C17 关键字（决策 005） *)
let keywords : (string, Tokens.token) Hashtbl.t = Hashtbl.create 64
let () =
  List.iter (fun (s, t) -> Hashtbl.add keywords s t) [
    "auto", AUTO; "break", BREAK; "case", CASE; "char", CHAR;
    "const", CONST; "continue", CONTINUE; "default", DEFAULT; "do", DO;
    "double", DOUBLE; "else", ELSE; "enum", ENUM; "extern", EXTERN;
    "float", FLOAT; "for", FOR; "goto", GOTO; "if", IF;
    "inline", INLINE; "int", INT; "long", LONG; "register", REGISTER;
    "restrict", RESTRICT; "return", RETURN; "short", SHORT; "signed", SIGNED;
    "sizeof", SIZEOF; "static", STATIC; "struct", STRUCT; "switch", SWITCH;
    "typedef", TYPEDEF; "union", UNION; "unsigned", UNSIGNED; "void", VOID;
    "volatile", VOLATILE; "while", WHILE;
    "_Alignas", ALIGNAS; "_Alignof", ALIGNOF; "_Atomic", ATOMIC;
    "_Bool", BOOL; "_Complex", COMPLEX; "_Generic", GENERIC;
    "_Imaginary", IMAGINARY; "_Noreturn", NORETURN;
    "_Static_assert", STATIC_ASSERT; "_Thread_local", THREAD_LOCAL;
  ]

(* 行标记 / #pragma 的行尾换行在规则里一并吃掉，这里统一记账 *)
let count_nl_if_any lexbuf =
  let s = Lexing.lexeme lexbuf in
  if String.length s > 0 && s.[String.length s - 1] = '\n'
  then Lexing.new_line lexbuf
}

let digit    = ['0'-'9']
let nondigit = ['A'-'Z' 'a'-'z' '_']
let hexdig   = ['0'-'9' 'a'-'f' 'A'-'F']
let ws       = [' ' '\t' '\011' '\012' '\r']

(* pp-number（C17 §6.4.8）：数字先按预处理数整词切出，与 gcc 同口径
   （DESIGN.md §3 / Q13：合法输入上与精确切法等价，非法词素整词报错） *)
let ppnum = '.'? digit (digit | nondigit | '.' | ['e' 'E' 'p' 'P'] ['+' '-'])*

(* 精确数值文法：只用于 classify_num 对整个 pp-number 的校验分类。
   八进制拼写被 digit+ 覆盖，八进制的解释与合法性归语义层。 *)
let isuffix   = ['u' 'U'] ("ll" | "LL" | ['l' 'L'])?
              | ("ll" | "LL" | ['l' 'L']) ['u' 'U']?
let int_lit   = (("0x" | "0X") hexdig+ | ("0b" | "0B") ['0' '1']+ | digit+) isuffix?
let fsuffix   = ['f' 'F' 'l' 'L']
let expo      = ['e' 'E'] ['+' '-']? digit+
let dec_float = ((digit* '.' digit+ | digit+ '.') expo? | digit+ expo) fsuffix?
(* 十六进制浮点必须带二进制指数：没有 p 的 0x1.8 是非法词素 *)
let hex_float = ("0x" | "0X") (hexdig* '.' hexdig+ | hexdig+ '.'?)
                ['p' 'P'] ['+' '-']? digit+ fsuffix?

(* 字面量内容按字节透明（UTF-8 直接通过）；转义不展开，原样保留（决策 007） *)
let schar      = [^ '"' '\\' '\n']
let cchar      = [^ '\'' '\\' '\n']
let escape     = '\\' [^ '\n']
let str_prefix = "u8" | "u" | "U" | "L"
let chr_prefix = ['u' 'U' 'L']          (* C17 没有 u8'' 字符字面量 *)

rule token lmap = parse
  | '\n'  { Lexing.new_line lexbuf; token lmap lexbuf }
  | ws+   { token lmap lexbuf }

  (* ---- '#'：行首 = 行标记/#pragma；行中 = 非法（DESIGN.md §2 条 4）。
     ocamllex 没有行首锚，用「词素起点 = 行起点」判断 ---- *)
  | '#'   { let p = Lexing.lexeme_start_p lexbuf in
            if p.Lexing.pos_cnum = p.Lexing.pos_bol
            then directive lmap lexbuf
            else error lmap lexbuf
                   "行中出现 '#'（stray '#'，或输入未经预处理）" }

  (* ---- 未预处理探测（DESIGN.md §2 条 1、2） ---- *)
  | "/*"      { unpreprocessed lmap lexbuf "发现块注释 '/*'" }
  | "//"      { unpreprocessed lmap lexbuf "发现行注释 '//'" }
  | '\\' '\n' { unpreprocessed lmap lexbuf "行尾出现 '\\'，行接续残留" }

  (* ---- 字符串 / 字符字面量：一条 token，payload = 原始拼写 ---- *)
  | (str_prefix? '"' (schar | escape)* '"') as s   { STRING_LIT s }
  | str_prefix? '"' (schar | escape)* '\\'? ('\n' | eof)
      { error lmap lexbuf "未闭合的字符串字面量" }
  | (chr_prefix? '\'' (cchar | escape)* '\'') as s { CHAR_LIT s }
  | chr_prefix? '\'' (cchar | escape)* '\\'? ('\n' | eof)
      { error lmap lexbuf "未闭合的字符字面量" }

  (* ---- 数字：pp-number 整词切出，再整词校验分类（DESIGN.md §3） ---- *)
  | ppnum as s
      { match classify_num (Lexing.from_string s) with
        | `Int   -> INT_LIT s
        | `Float -> FLOAT_LIT s
        | `Bad   -> error lmap lexbuf
                      (Printf.sprintf "非法数字字面量 '%s'" s) }

  (* ---- 标识符 / 关键字（__attribute__ 等 GNU 扩展在这里自然成为 IDENT） ---- *)
  | (nondigit (nondigit | digit)*) as s
      { match Hashtbl.find_opt keywords s with
        | Some kw -> kw
        | None    -> IDENT s }

  (* ---- 双字符组：归一化到对应标点（C17 §6.4.6p3，拼写不保留） ---- *)
  | "<:" { LBRACKET } | ":>" { RBRACKET }
  | "<%" { LBRACE }   | "%>" { RBRACE }
  | "%:%:" | "%:"
      { error lmap lexbuf
          "出现双字符组 '%:'（即 '#'，合法的已预处理 C 里不该有）" }

  (* ---- 标点 ---- *)
  | "..." { ELLIPSIS }
  | "<<=" { LSHIFT_ASSIGN } | ">>=" { RSHIFT_ASSIGN }
  | "->"  { ARROW } | "++" { INC } | "--" { DEC }
  | "<<"  { LSHIFT } | ">>" { RSHIFT }
  | "<="  { LE } | ">=" { GE } | "==" { EQEQ } | "!=" { NEQ }
  | "&&"  { ANDAND } | "||" { OROR }
  | "*="  { STAR_ASSIGN } | "/=" { SLASH_ASSIGN } | "%=" { PERCENT_ASSIGN }
  | "+="  { PLUS_ASSIGN } | "-=" { MINUS_ASSIGN }
  | "&="  { AMP_ASSIGN } | "^=" { CARET_ASSIGN } | "|=" { PIPE_ASSIGN }
  | '['   { LBRACKET } | ']' { RBRACKET } | '(' { LPAREN } | ')' { RPAREN }
  | '{'   { LBRACE } | '}' { RBRACE }
  | '.'   { DOT } | '&' { AMP } | '*' { STAR } | '+' { PLUS } | '-' { MINUS }
  | '~'   { TILDE } | '!' { BANG } | '/' { SLASH } | '%' { PERCENT }
  | '<'   { LT } | '>' { GT } | '^' { CARET } | '|' { PIPE }
  | '?'   { QUESTION } | ':' { COLON } | ';' { SEMI } | '=' { ASSIGN }
  | ','   { COMMA }
  | eof   { EOF }
  | _     { error lmap lexbuf
              (Printf.sprintf "非法字符 '%s'"
                 (String.escaped (Lexing.lexeme lexbuf))) }

(* '#' 之后的部分。行尾换行在这里吃掉并记账，
   使行标记入表时 lex_curr_p.pos_lnum 恰好指向「下一行」——
   与「# N 表示下一行是原文件第 N 行」的语义对齐，避开差一格（DESIGN.md §4）。 *)
and directive lmap = parse
  (* 行标记：# N "文件" [标志...]；标志 3 = 系统头（决策 006） *)
  | ws* (digit+ as n) ws* '"' ([^ '"' '\n']* as file) '"'
    ([^ '\n']* as flags) ('\n' | eof)
      { count_nl_if_any lexbuf;
        let system_header =
          List.exists (fun f -> f = "3") (String.split_on_char ' ' flags) in
        Line_map.add lmap
          ~phys_line:lexbuf.Lexing.lex_curr_p.Lexing.pos_lnum
          ~file ~orig_line:(int_of_string n) ~system_header;
        token lmap lexbuf }

  (* #pragma：唯一合法活到编译器本体的预处理指令，先整行吞掉。
     TODO(决策 006)：将来支持 #pragma pack 等时，从这里开始解析。 *)
  | ws* "pragma" ([^ '\n']*) ('\n' | eof)
      { count_nl_if_any lexbuf; token lmap lexbuf }

  (* 残留的预处理指令 = 未预处理输入的直接证据（DESIGN.md §2 条 3） *)
  | ws* (("include" | "define" | "undef" | "ifdef" | "ifndef" | "if"
        | "elif" | "else" | "endif" | "line" | "error" | "warning") as d)
      { unpreprocessed lmap lexbuf (Printf.sprintf "残留 #%s 指令" d) }

  | ""  { error lmap lexbuf "无法识别的 '#' 行" }

(* 对单个 pp-number 词素整词校验分类（DESIGN.md §3）。
   实测口径（2026-08-26）：合法输入上与精确切法完全等价；
   0x1e+2、123abc 这类非法词素整词报错，与 gcc 行为一致。 *)
and classify_num = parse
  | int_lit eof                   { `Int }
  | (dec_float | hex_float) eof   { `Float }
  | ""                            { `Bad }
