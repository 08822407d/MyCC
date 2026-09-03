# ex10_type_and — 相互引用的类型 + 相互递归的函数

**要编辑的文件：`main.ml`**，只改「你的代码」那一段。分隔线以下别动。

## 这题在练什么

只有一个新东西：**`and`**。

- `type entry = … and folder = …` —— 两个类型互相提到对方，捆成一组
- `let rec f … and g …` —— 两个函数互相调用，捆成一组

类型已经给好了，你要写的是 5 组函数。

## 数据长这样

```
proj/
  README.md      120
  src/
    main.ml      300
    dune          40
  empty/
  LICENSE         60
```

## 跑

```bash
bash ./scripts/ocaml.sh run ex10_type_and
```

一共 16 条。没写完也能跑，会逐条报「还没做」。

## 用得上的东西

全是学过的：`match`、记录取字段 `f.name`、`List.fold_left` / `fold_right`、
`@`（接表）、内置的 `max`。

⛔ 不需要 option、异常、ref。
