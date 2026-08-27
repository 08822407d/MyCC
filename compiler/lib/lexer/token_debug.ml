(* token_debug.ml — token → 规范拼写。
   CLI 的默认输出（每 token 一行）就吃这个，T2 往返测试直接编译它（决策 008）。
   menhir 生成的 Tokens 模块不能改，所以打印函数放这里（决策 007 的已知代价）。 *)

open Tokens

let to_spelling = function
  (* 关键字 *)
  | AUTO -> "auto" | BREAK -> "break" | CASE -> "case" | CHAR -> "char"
  | CONST -> "const" | CONTINUE -> "continue" | DEFAULT -> "default"
  | DO -> "do" | DOUBLE -> "double" | ELSE -> "else" | ENUM -> "enum"
  | EXTERN -> "extern" | FLOAT -> "float" | FOR -> "for" | GOTO -> "goto"
  | IF -> "if" | INLINE -> "inline" | INT -> "int" | LONG -> "long"
  | REGISTER -> "register" | RESTRICT -> "restrict" | RETURN -> "return"
  | SHORT -> "short" | SIGNED -> "signed" | SIZEOF -> "sizeof"
  | STATIC -> "static" | STRUCT -> "struct" | SWITCH -> "switch"
  | TYPEDEF -> "typedef" | UNION -> "union" | UNSIGNED -> "unsigned"
  | VOID -> "void" | VOLATILE -> "volatile" | WHILE -> "while"
  | ALIGNAS -> "_Alignas" | ALIGNOF -> "_Alignof" | ATOMIC -> "_Atomic"
  | BOOL -> "_Bool" | COMPLEX -> "_Complex" | GENERIC -> "_Generic"
  | IMAGINARY -> "_Imaginary" | NORETURN -> "_Noreturn"
  | STATIC_ASSERT -> "_Static_assert" | THREAD_LOCAL -> "_Thread_local"
  (* 标点（双字符组已在词法层归一化，这里只有规范拼写） *)
  | LBRACKET -> "[" | RBRACKET -> "]" | LPAREN -> "(" | RPAREN -> ")"
  | LBRACE -> "{" | RBRACE -> "}"
  | DOT -> "." | ARROW -> "->" | INC -> "++" | DEC -> "--"
  | AMP -> "&" | STAR -> "*" | PLUS -> "+" | MINUS -> "-"
  | TILDE -> "~" | BANG -> "!" | SLASH -> "/" | PERCENT -> "%"
  | LSHIFT -> "<<" | RSHIFT -> ">>"
  | LT -> "<" | GT -> ">" | LE -> "<=" | GE -> ">="
  | EQEQ -> "==" | NEQ -> "!=" | CARET -> "^" | PIPE -> "|"
  | ANDAND -> "&&" | OROR -> "||"
  | QUESTION -> "?" | COLON -> ":" | SEMI -> ";" | ELLIPSIS -> "..."
  | ASSIGN -> "=" | STAR_ASSIGN -> "*=" | SLASH_ASSIGN -> "/="
  | PERCENT_ASSIGN -> "%=" | PLUS_ASSIGN -> "+=" | MINUS_ASSIGN -> "-="
  | LSHIFT_ASSIGN -> "<<=" | RSHIFT_ASSIGN -> ">>="
  | AMP_ASSIGN -> "&=" | CARET_ASSIGN -> "^=" | PIPE_ASSIGN -> "|="
  | COMMA -> ","
  (* 字面量与标识符：payload 就是原始拼写 *)
  | IDENT s | INT_LIT s | FLOAT_LIT s | CHAR_LIT s | STRING_LIT s -> s
  | EOF -> ""
