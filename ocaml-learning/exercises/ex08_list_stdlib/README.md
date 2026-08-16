# ex08_list_stdlib — `List` 模块常用函数

**要编辑的文件只有一个：[`main.ml`](main.ml)**，只改「你的代码」那一段。

## 这题在练什么

**不是算法，是「想干这件事该拿哪个函数」。** 八道题**每道都是一行**——
如果你写出了递归，说明拿错工具了。

起因：你自己说的「`list` 的几个常用成员函数又想不起来了」。
**光看表记不住，得过一遍手。**

## 速查表（做题时可以看）

| 想干什么 | 用哪个 |
|---|---|
| 对每个元素做副作用 | `iter` —— **返回 `unit`**，要攒结果得配 `ref` |
| 变换每个元素 | `map` / `mapi`（带下标） |
| 挑一部分 | `filter` |
| 收拢成一个值 | `fold_left` / `fold_right` |
| 问「**有没有**」 | `exists` |
| 问「**是不是全都**」 | `for_all` |
| 问「**含不含这个值**」 | `mem`（直接给值，不用写谓词） |
| 找第一个满足的 | `find` —— ⚠️ **找不到抛 `Not_found`** |
| 一刀两断 | `partition` —— **返回元组** |
| 排序 | `sort` —— 要 comparator，**就是 C 的 `qsort`** |
| 切前/后 n 个 | `take` / `drop` |

**排序的 comparator**（回收 C1 的 `qsort`）：

```ocaml
List.sort compare lst                      (* 升序 *)
List.sort (fun a b -> compare b a) lst     (* 降序：把两个参数掉个个儿 *)
```

## 需要的知识（全部讲过）

| 东西 | 在哪讲的 |
|---|---|
| `map` / `filter` / `fold` | C1 / C2，`concepts/15` |
| `ref` / `:=` / `!` | 知识点 8 |
| `try … with` 接 `Not_found` | B3，`concepts/14` |
| 元组、`^` 拼接、`compare` | 知识点 6 / 17 |

⛔ **这题不用 `option`**（你要求推迟的那块），所以第 8 题用 `try … with` 接异常，
而不是 `find_opt`。标准库里凡是 `_opt` 结尾的都返回 `option`，等以后再说。

## 几个容易踩的点

- **TODO 1 必须用 `List.iter`**，不许用 `fold`。目的是体会「`iter` 返回 `unit`」
  ——这也是它和 `map` 的根本区别。
- **TODO 2 和 TODO 3 是一对兄弟**（`exists` / `for_all`），别拿反。
  ⚠️ 注意 `all_positive []` 期望 **`true`**：空表没有反例，所以「全都满足」成立。
- **TODO 4 不需要你写谓词**，有个函数直接收「值」。
- **TODO 6 返回元组**，有个函数一次给你两张表，不用调两遍 `filter`。

## 怎么验证

写完跟 Claude 说一声「好了」：

```bash
bash ./scripts/ocaml.sh run ex08_list_stdlib
```

没做完的题显示 `[--] 还没做`，不会让整个文件编译不过。
