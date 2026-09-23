# TXTForMac 项目档案（PROJECT_INFO）

> **用途**：项目级信息唯一载体 —— 技术栈 / 架构约定 / 代码风格 / 开发与部署信息。
> **读取时机**：Full 模式开工、架构设计、涉及服务器/部署/外部服务时，必须 Read 本文件。
> **安全规则**：本文件只写**地址与引用名**（如 `$SPARKLE_ED_PRIVATE_KEY_FILE`），
> **密钥值**一律存本机 600 权限文件或环境变量，禁止写入本项目任何文件。

## 常用命令

- 生成工程: `xcodegen generate`（改 `project.yml` 后必跑；`.xcodeproj` 一并入库）
- 构建: `xcodebuild -scheme TXTForMac -configuration Debug build`
- 测试: `xcodebuild -scheme TXTForMac -destination 'platform=macOS' test`
- 静态检查: `swiftlint --strict` / `swiftformat --lint .`
- 运行: `open build/Build/Products/Debug/TXTForMac.app`（或 `xcodebuild ... -derivedDataPath build` 后取该路径）
- 发布: `bash scripts/release.sh <version>`（打 tag、出 ZIP/DMG、更新 appcast、推 Release）

## 技术栈

- 主栈（profile）：`macos`
- 语言 / UI：Swift 6（语言模式 6）、SwiftUI 外壳 + AppKit（`NSTextView` / TextKit 2 编辑器内核、AppKit 主菜单、`NSFontPanel`、`NSPrintOperation`）
- 工程生成：xcodegen（`project.yml` 为唯一工程定义源；禁止手改 `.xcodeproj`）
- 依赖：Sparkle 2（SPM，仅用于更新）；除此之外零第三方依赖
- 最低系统：macOS 15.0；架构：Apple Silicon + Intel（universal）
- Bundle ID：`online.nonchalantludens.txtformac` / `.finder` / `.tests`

## 目录结构要点

```
TXTForMac/App         @main、AppDelegate、主菜单、窗口与命令路由
TXTForMac/Models      Document / DocumentStore / TextEncoding / LineEnding / AppSettings
TXTForMac/Services    FileIOService / EncodingDetector / SettingsStore / SessionStore / UpdaterService
TXTForMac/Editor      EditorController / TextEditorView / FindBar / GoToLineBar / StatusBar
TXTForMac/Tabs        标签栏与拖拽/开窗逻辑
TXTForMac/Settings    设置窗口与各分页
TXTForMac/Resources   Assets.xcassets / Localizable.xcstrings / *.lproj / Info.plist
TXTForMacFinder       Finder Sync 扩展（薄层，命名与配置逻辑复用 Shared）
Shared                两 target 共用：FileNaming / SettingsSchema / TextEncoding / LineEnding
TXTForMacTests        单元测试
scripts               release.sh 与发布辅助
```

## 架构约定

- 依赖方向：`App → Settings/Tabs/Editor → Services → Models`；`Shared` 只被依赖，不反向依赖 App 层
- 配置单一来源：`SettingsStore`（ADR-004），文件 `~/Library/Application Support/TXTForMac/config.json`
- 主 App 与 Finder 扩展**不使用 App Group**（ADR-002），靠同一份 JSON + `DistributedNotificationCenter` + mtime 校验同步
- 编辑器：单窗口单 `NSTextView` + 多 `Document` 模型（ADR-005），标签迁移即文档对象迁移
- 全部耗时 IO 在后台线程，UI 更新回 `@MainActor`
- 关键架构决策见 `devplaybook/SPEC/ADR.md`（ADR-001…006）

## 代码风格

- 命名：类型 PascalCase、方法/属性 camelCase；文件内不堆多个类型（避免巨型 View）
- UI 文案零硬编码：全部走 String Catalog（`Localizable.xcstrings`），en 基准 + zh-Hans
- 颜色/字号/间距零字面量：走 Asset Catalog Color Set 与 `EditorTheme` / 系统文本样式
- 错误处理：`throws` + 映射为友好文案（`LocalizedError`），禁止把系统错误原文直接抛给用户
- swiftlint / swiftformat 零 error

## 开发与部署信息

### Git

- 远程仓库：`https://github.com/NonchalantLudens/TXTForMac.git`
- 默认分支：`main`；功能开发走 `feature/<名称>`（C9），Quick 模式小修可直接提交 main
- 更新 feed：`https://nonchalantludens.github.io/TXTForMac/appcast.xml`（gh-pages 分支托管）

### 分发与签名

| 项 | 值 |
|---|---|
| 签名 | ad-hoc（`codesign -s -`），不做公证（ADR-003） |
| 更新框架 | Sparkle 2，EdDSA 签名校验 |
| 产物 | `TXTForMac-<version>.zip`（Sparkle 用）+ `TXTForMac-<version>.dmg`（人装用） |
| Release 附件 | 上述两个文件，挂在对应 tag 下 |

### 服务器 / SSH

| 用途 | 主机 | 用户 | 密钥 | 备注 |
|---|---|---|---|---|
| — | 无（纯客户端 + GitHub Pages） | — | — | 无自建服务器 |

### 密钥引用（只写引用名，值存本机 600 文件）

| 引用名 | 用途 | 所在环境 |
|---|---|---|
| `$SPARKLE_ED_PRIVATE_KEY_FILE` | Sparkle EdDSA 私钥路径（`~/.config/txtformac/sparkle_ed25519`） | 本机，权限 600，禁入仓库 |
| `$GH_TOKEN` | 发布脚本推送 Release / gh-pages（通常由 `gh` 键串自动提供） | `gh` 凭据助手 |
