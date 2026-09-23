# TXTForMac 已有资产清单（ASSETS）

> **用途**：防重复造轮子 —— 写任何新函数/组件前先查本文件（C6）。
> **维护**：新增可复用资产时登记到「已建资产」；找不到而新写时，在「新写记录」登记搜索路径与理由。

## 一、系统与框架提供（首选复用，不要自己写）

| 资产 | 来源 | 用途 |
|---|---|---|
| `NSTextView` + TextKit 2 | AppKit | 编辑器内核（找/替换、撤销、布局、打印） |
| `NSUndoManager` | Foundation | 撤销栈（每文档一个） |
| `NSFontPanel` | AppKit | 字体选择（不要自绘字体选择器） |
| `NSPrintOperation` | AppKit | 打印与页面设置 |
| `NSSavePanel` / `NSOpenPanel` | AppKit | 文件选择 + accessoryView 挂编码/换行符选项 |
| `NSWorkspace.setDefaultApplication(at:toOpenFileAt:)` | AppKit (macOS 12+) | 设为默认文本编辑器 |
| `String(contentsOf:encoding:)` / `write(to:atomically:encoding:)` | Foundation | 文件读写（原子写复用 `atomically` 或 `FileManager.replaceItemAt`） |
| `CFStringConvertEncodingToNSStringEncoding` | CoreFoundation | GB18030/Big5/Shift-JIS ↔ `String.Encoding` |
| `DistributedNotificationCenter` | Foundation | 主 App ↔ Finder 扩展 配置变更广播 |
| `FIFinderSync` / `FIFinderSyncController` | FinderSync | 右键菜单与监控目录 |
| `NSServices`（Info.plist）+ `NSApp.servicesProvider` | AppKit | 快速操作兜底入口 |
| `SPUStandardUpdaterController` | Sparkle 2 | 更新检查/下载/安装 |
| `String Catalog`（`.xcstrings`） | Xcode | 双语本地化 |
| `Color Set`（Asset Catalog） | Xcode | 颜色 token（ADR-006） |
| `FileManager.replaceItemAt` | Foundation | 原子替换保存 |

## 二、已建资产（项目内复用）

| 资产 | 位置 | 用途 | 建立于 |
|---|---|---|---|
| （待建）`LineEnding` | `Shared/LineEnding.swift` | 换行符模型 | T-005 |
| （待建）`TextEncoding` | `Shared/TextEncoding.swift` | 编码模型与 BOM | T-006 |
| （待建）`SettingsSchema` | `Shared/SettingsSchema.swift` | 配置键名唯一来源（两 target 共用） | T-032 |
| （待建）`FileNaming` | `Shared/FileNaming.swift` | 命名模板与冲突策略（主 App 与扩展共用） | T-040 |
| （待建）`EditorTheme` | `TXTForMac/Editor/EditorTheme.swift` | 编辑器配色/字号 token | T-037 |
| （待建）`FileIOService` | `TXTForMac/Services/FileIOService.swift` | 全部文件读写（禁旁路） | T-008/T-009 |
| （待建）`SettingsStore` | `TXTForMac/Services/SettingsStore.swift` | 全部设置读写（禁旁路） | T-032 |

## 三、新写记录

| 新写资产 | 搜索过的路径/关键词 | 未复用理由 |
|---|---|---|
| — | — | — |
