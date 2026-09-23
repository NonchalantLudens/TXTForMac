# TXTForMac 提交规范（COMMIT_GUIDE）

> **默认**：本项目遵循全局提交约定（见下）。**如需不同，整节改写本文件**（本文件为项目内容，update 永不覆盖）。
> **强制**：格式由 commit-msg hook 硬校验，不符合即拦截提交（`git commit --no-verify` 可紧急跳过）。
> **hook 校验规则**：type 集合默认与本文档一致；项目自定义 type 时在 `devplaybook/rules/local.conf` 加
> `@commit-types=type1|type2|...` 覆盖。

## 默认约定（全局）

- 格式：`<type>(<scope>): <description>` + 可选正文 + 可选 footer
- 类型：`feat` 新功能 / `fix` 缺陷修复 / `perf` 性能 / `refactor` 重构 / `docs` 文档 /
  `test` 测试 / `chore` 构建杂项 / `icon` 图标 / `tweak` 微调 / `release` 版本发布
- scope（可选）：改动模块名（如 controller/settings/view/scripts/readme/cask）
- 描述：祈使句、≤72 字符、说明"做了什么"；中文项目用中文；不以句号结尾
- 破坏性变更：`refactor!: ...` + footer `BREAKING CHANGE: ...`
- `feat`/`fix` 需同步更新 CHANGELOG；发布 tag 格式 `vMAJOR.MINOR.PATCH`

---

## 项目定制区（如与默认不同，改写以下内容）

（默认遵循全局约定，无需修改。若项目需自定义提交规范，在此整节替换。）
