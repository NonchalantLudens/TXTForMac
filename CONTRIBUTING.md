# Contributing to TXTForMac / 参与贡献 TXTForMac

Thanks for your interest in contributing. / 感谢你有兴趣参与贡献。

[English](#english) | [简体中文](#简体中文)

## English

### Getting started

```bash
git clone https://github.com/NonchalantLudens/TXTForMac.git
cd TXTForMac
brew install xcodegen swiftlint swiftformat
xcodegen generate
open TXTForMac.xcodeproj     # then ⌘R
```

The Xcode project is generated from `project.yml` — **never edit `TXTForMac.xcodeproj`
by hand**. After adding or moving files, re-run `xcodegen generate`.

### Ground rules

1. **Feature branches.** Do not commit features directly to `main`; use
   `feature/<short-name>`.
2. **TDD.** Write the failing test first, then the implementation. Pure logic
   (encoding detection, line endings, naming conflicts, settings) must stay unit-tested.
3. **Zero-warning lint.** `swiftlint --strict` and `swiftformat --lint .` must pass.
4. **No hardcoded UI copy.** All user-visible text goes through the localization files
   (`en.lproj` / `zh-Hans.lproj`), in both languages.
5. **No placeholder implementations.** `TODO`/stub/mock code will be rejected.
6. **Conventional Commits.** `<type>(<scope>): <description>` with types
   `feat|fix|perf|refactor|docs|test|chore|icon|tweak|release`; description ≤72 chars,
   no trailing period. `feat`/`fix` must update `CHANGELOG.md`.
7. Update `README.md` **and** `README.zh-CN.md` together, same for `CHANGELOG.md`.

### Submitting

Open a pull request with a short description, the tested behaviour, and screenshots/GIFs
for UI changes.

## 简体中文

### 准备环境

```bash
git clone https://github.com/NonchalantLudens/TXTForMac.git
cd TXTForMac
brew install xcodegen swiftlint swiftformat
xcodegen generate
open TXTForMac.xcodeproj     # 然后 ⌘R
```

Xcode 工程由 `project.yml` 生成 —— **不要手改 `TXTForMac.xcodeproj`**。
新增或移动文件后，重新执行 `xcodegen generate`。

### 基本规矩

1. **功能分支开发。** 不要把功能直接提交到 `main`，请使用 `feature/<短名>`。
2. **TDD。** 先写失败测试，再写实现。纯逻辑（编码检测、换行符、命名冲突、设置）
   必须有单元测试。
3. **静态检查零警告。** `swiftlint --strict` 与 `swiftformat --lint .` 必须通过。
4. **界面文案零硬编码。** 全部用户可见文本走本地化文件（`en.lproj` / `zh-Hans.lproj`），
   两种语言同步维护。
5. **禁止占位实现。** `TODO`/stub/mock 代码会被打回。
6. **Conventional Commits。** 格式 `<type>(<scope>): <描述>`，type 取
   `feat|fix|perf|refactor|docs|test|chore|icon|tweak|release`；描述 ≤72 字符，
   不以句号结尾。`feat`/`fix` 需同步更新 `CHANGELOG.md`。
7. `README.md` 与 `README.zh-CN.md` 同步更新，`CHANGELOG.md` 同理。

### 提交

发起 Pull Request 时请附简述、已验证的行为；UI 改动请附截图或 GIF。
