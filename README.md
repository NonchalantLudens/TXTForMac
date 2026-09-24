# TXTForMac

> A lightweight text editor for macOS, with the full muscle memory of Windows Notepad.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2015%2B-lightgrey.svg)
![Language](https://img.shields.io/badge/language-Swift-orange.svg)

[English](README.md) | [简体中文](README.zh-CN.md)

TXTForMac is a native macOS text editor built with Swift. It recreates the workflow of the
Windows Notepad — honest plain text, reliable encodings, zero ceremony — and adds the things
macOS users expect: tabs, session restore, a real settings window, Finder integration and
automatic updates.

**v1.0.0 released!** Download it from the
[Releases](https://github.com/NonchalantLudens/TXTForMac/releases) page — the app checks for updates automatically.

## Features

- **Encoding done right** — UTF-8 (with or without BOM), UTF-16 LE/BE, GB18030/GBK, Big5,
  Shift-JIS and Latin-1; automatic detection with a one-click "reopen with encoding" escape hatch
- **Line endings preserved** — CRLF / LF / CR are detected, shown in the status bar and converted on demand
- **Round-trip safe saving** — files keep their original encoding and line endings; saves are atomic
- **Full Notepad toolkit** — find & replace (with regex), go to line, insert time/date (`F5`),
  font panel, zoom, word wrap, printing
- **Tabs** — drag to reorder, drag out into a separate window, drag back to merge
- **Nothing is ever lost** — autosave, crash-safe session restore, unsaved-changes prompts
- **A real settings window** — language, editor, files, appearance, Finder integration, updates
- **Finder integration** — right-click "New Text File" in monitored folders, with naming templates
  and conflict policies; a Quick Action covers every other folder
- **Automatic updates** — Sparkle-based, EdDSA-signed, fed from GitHub Releases
- **Bilingual UI** — English and 简体中文, switchable at runtime

## System Requirements

| Item | Requirement |
| --- | --- |
| macOS | 15.0 (Sequoia) or later |
| Architecture | Apple Silicon or Intel |

## Installation

Download the latest DMG from the [Releases](https://github.com/NonchalantLudens/TXTForMac/releases)
page, open it and drag **TXTForMac** into **Applications**.

**First launch (unsigned build):** the app is not notarized, so macOS may block the first start.
Right-click the app → **Open** → confirm, or run:

```bash
xattr -dr com.apple.quarantine /Applications/TXTForMac.app
```

## Building

```bash
git clone https://github.com/NonchalantLudens/TXTForMac.git
cd TXTForMac
xcodegen generate                       # requires xcodegen: brew install xcodegen
xcodebuild -scheme TXTForMac -destination 'platform=macOS' build
```

Open `TXTForMac.xcodeproj` in Xcode and press ⌘R to run. Static checks used by CI:

```bash
swiftlint --strict        # brew install swiftlint
swiftformat --lint .      # brew install swiftformat
```

## Project Structure

```
TXTForMac/            App target: App / Models / Services / Editor / Tabs / Settings / Resources
TXTForMacFinder/      Finder Sync extension target (right-click "New Text File")
Shared/               Code shared by both targets: settings schema, value types, file naming
TXTForMacTests/       Unit tests
scripts/              Release tooling
project.yml           xcodegen project definition (single source of truth)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). In short: feature branches, TDD, zero-warning lint,
Conventional Commits.

## License

[MIT](LICENSE) © NonchalantLudens
