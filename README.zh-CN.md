# TXTForMac

> macOS 上的轻量文本编辑器，完整还原 Windows 记事本的操作习惯。

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2015%2B-lightgrey.svg)
![Language](https://img.shields.io/badge/language-Swift-orange.svg)

[English](README.md) | [简体中文](README.zh-CN.md)

TXTForMac 是用 Swift 打造的原生 macOS 文本编辑器。它还原 Windows 记事本的工作方式 ——
老实的纯文本、可靠的编码、零负担 —— 再补上 macOS 用户期待的标签页、会话恢复、完整设置、
Finder 集成与自动更新。

**v1.0.0 已发布！** 从
[Releases](https://github.com/NonchalantLudens/TXTForMac/releases) 页面下载，应用会自动检查更新。

## 功能

- **编码做对** —— UTF-8（含/不含 BOM）、UTF-16 LE/BE、GB18030/GBK、Big5、Shift-JIS、Latin-1；
  自动识别，误判可一键「以指定编码重新打开」
- **换行符保真** —— CRLF / LF / CR 自动识别，状态栏随时切换并即时转换
- **保存往返无损** —— 文件保持原编码与换行符；保存为原子写，不产生半截文件
- **记事本全套** —— 查找替换（含正则）、转到行、插入时间日期（`F5`）、字体面板、缩放、自动换行、打印
- **标签页** —— 拖拽重排、拖出成独立窗口、拖回合并
- **内容不丢** —— 自动保存、崩溃级会话恢复、未保存改动三选提示
- **完整设置页** —— 通用 / 编辑 / 文件 / 外观 / 右键集成 / 更新 / 关于
- **Finder 集成** —— 监控目录内右键顶级「新建文本文件」，支持命名模板与冲突策略；
  其余目录由快速操作兜底
- **自动更新** —— 基于 Sparkle，EdDSA 签名校验，托管于 GitHub Releases
- **双语界面** —— English 与简体中文，运行时即时切换

## 系统要求

| 项目 | 要求 |
| --- | --- |
| macOS | 15.0 (Sequoia) 或更高 |
| 架构 | Apple Silicon 或 Intel |

## 安装

从 [Releases](https://github.com/NonchalantLudens/TXTForMac/releases) 页面下载最新 DMG，
打开并把 **TXTForMac** 拖入 **Applications**。

**首次启动（未公证版本）：** macOS 可能拦截首次启动。右键应用 → **打开** → 确认；
或执行：

```bash
xattr -dr com.apple.quarantine /Applications/TXTForMac.app
```

## 构建

```bash
git clone https://github.com/NonchalantLudens/TXTForMac.git
cd TXTForMac
xcodegen generate                       # 需要 xcodegen：brew install xcodegen
xcodebuild -scheme TXTForMac -destination 'platform=macOS' build
```

用 Xcode 打开 `TXTForMac.xcodeproj` 后 ⌘R 运行。CI 使用的静态检查：

```bash
swiftlint --strict        # brew install swiftlint
swiftformat --lint .      # brew install swiftformat
```

## 目录结构

```
TXTForMac/            主 App：App / Models / Services / Editor / Tabs / Settings / Resources
TXTForMacFinder/      Finder Sync 扩展（右键新建文本文件）
Shared/               两 target 共用：配置结构、值类型、文件命名
TXTForMacTests/       单元测试
scripts/              发布脚本
project.yml           xcodegen 工程定义（唯一来源）
```

## 参与贡献

见 [CONTRIBUTING.md](CONTRIBUTING.md)。简要：功能分支、TDD、零警告静态检查、Conventional Commits。

## 许可

[MIT](LICENSE) © NonchalantLudens
