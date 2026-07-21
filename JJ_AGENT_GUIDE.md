# Report Workspace jj 速查

本工作区使用本地 Jujutsu（`jj`）记录编辑历史。仓库已经由系统初始化，不需要远端，也不要再次
执行 `jj git init`。

## 心智模型

- `@` 是当前可继续修改的 working-copy change。
- `@-` 是它的父 change，通常是上一个 checkpoint。
- 没有 Git staging area；不要执行 `git add`、`git commit` 或 `git push`。
- `jj status`、`jj diff` 等命令开始时会先快照当前文件状态。

## 日常检查

```sh
cd /workspace
jj status
jj diff --stat
jj diff
```

简单修改检查 diff 即可，不必机械创建 checkpoint。

## 创建 checkpoint

完成一个连贯的多文件修改后：

```sh
jj diff
jj describe -m "简短说明本次修改"
jj new
```

`describe` 给当前 `@` 命名，`new` 在它之后创建新的空 change 继续工作。不要在检查 diff 之前创建
checkpoint，也不要为每次小改动创建一个 change。

## 查看历史

```sh
jj log --limit 10
jj show @-
jj diff --from @-- --to @-
```

优先查看历史，不要为了阅读旧版本而改写当前文件。

## 恢复文件

浏览器可能同时修改工作区。只有用户明确要求回退，而且已经重新读取当前文件并确认不会覆盖后来修改时，
才执行路径级恢复：

```sh
jj diff
jj restore --from @- reports/目标文件.md
```

不要自行执行 `jj undo`、`jj op restore`、`jj abandon`、`jj rebase`、`jj squash` 或 `jj split`。

## 工作区边界

`sources/`、`evidence/`、`searches/`、`templates/`、`tools/` 和 Report Agent 内部元数据不会进入
编辑记录。Office 二进制文件只能显示文件级变化；正文、计算依据和可审计说明应优先保存在 Markdown、
JSON 或工具状态文件中。
