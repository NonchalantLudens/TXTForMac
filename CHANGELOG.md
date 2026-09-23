# Changelog

All notable changes to this project are documented in this file.
本文件记录本项目的全部显著变更，中英双语。

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added / 新增

- Project scaffold: xcodegen-driven app + unit-test targets, macOS 15.0, ad-hoc signing. / 工程骨架：xcodegen 驱动的 App 与单元测试 target，macOS 15.0，ad-hoc 签名。
- Settings foundation: `AppSettings` covering the full settings inventory plus a single
  read/write entry point (`SettingsStore`) with atomic writes, corrupt-file backup and
  change broadcast. / 设置基座：覆盖全部设置项的 `AppSettings`，以及唯一读写入口
  `SettingsStore`（原子写盘、损坏备份、变更广播）。
- Bilingual UI skeleton with runtime language switching (English / 简体中文). / 双语骨架与运行时语言切换（English / 简体中文）。
- Static checks wired into the commit hook (swiftlint + swiftformat). / 静态检查接入提交钩子（swiftlint + swiftformat）。
