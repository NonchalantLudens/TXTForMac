# TXTForMac 架构决策记录（ADR）

> **用途**：记录不可轻易推翻的架构取舍及其代价。冲突时以本文件为准，改决策须追加新 ADR 说明取代关系。
> 本文件为项目内容，update 永不覆盖。

---

## ADR-001：编辑器内核使用 AppKit `NSTextView`(TextKit 2)，SwiftUI 仅作外壳

- 状态：已接受（2026-09-23）
- 背景：需求要还原 Windows 记事本 —— 行列状态、打印、编码读写、原生撤销栈、字体面板、大文件性能。
- 决策：编辑器主体用 `NSTextView`，以 `NSViewRepresentable` 嵌入 SwiftUI；窗口/菜单/设置/标签栏用 SwiftUI（菜单为精确控制用 AppKit 构建）。
- 代价：SwiftUI 与 AppKit 桥接代码需要小心（焦点、撤销栈、响应链）；不能享受纯 SwiftUI 的声明式一致性。
- 备选与否决理由：`TextEditor`（无法拿到行列/打印/TextKit 布局控制）；自绘文本视图（工作量与正确性风险不可接受）。

## ADR-002：主 App 与 Finder 扩展之间不使用 App Group

- 状态：已接受（2026-09-23）
- 背景：Finder 扩展需要与主 App 共享「监控目录 / 菜单标题 / 命名模板 / 冲突策略」等配置。
- 决策：共享单一 JSON —— `~/Library/Application Support/TXTForMac/config.json`；变更经 `DistributedNotificationCenter` 广播，扩展端按 mtime 校验后热重载。键名定义在 `Shared/SettingsSchema`，两侧共用。
- 理由：`com.apple.security.application-groups` entitlement 需 Team ID 授权，本项目采用 ad-hoc 签名（无 Developer ID），容器创建会失败。非沙盒下普通路径读写对两侧均可用。
- 代价：失去 App Group 的沙盒化隔离；需自行处理并发写（原子写 + mtime 校验）。
- 替代路径：若将来购买 Developer ID 并启用沙盒，可平滑迁移到 App Group（只需替换 `SettingsStore` 的路径解析与通知机制，键名与模型不变）。

## ADR-003：签名为 ad-hoc + Sparkle EdDSA，不做公证

- 状态：已接受（2026-09-23）
- 背景：无 Apple Developer ID，公证不可用；但需要安全的自动更新。
- 决策：`codesign -s -` ad-hoc 签名；更新包由 Sparkle EdDSA 签名验证（公钥入 Info.plist，私钥仅存本机 600 权限）。首次启动由用户右键打开。
- 代价：新用户安装有 Gatekeeper 摩擦；Sparkle 的代码签名一致性校验失效，安全边界完全依赖 EdDSA。
- 后续：若取得 Developer ID，仅需补签名设置 + notarytool 流程，`release.sh` 已预留。

## ADR-004：配置单一来源 + 显式迁移

- 状态：已接受（2026-09-23）
- 决策：所有设置读写只经 `SettingsStore`；`AppSettings` 为 Codable 结构，带 `schemaVersion`；文件缺失或字段缺失回落默认值，解析失败降级为默认并备份损坏文件（`.corrupt-<时间戳>`）后重建。
- 理由：C3 零硬编码 + US-007 验收 4；避免散落的 UserDefaults 键成为隐性契约。

## ADR-005：标签页采用「单编辑器视图 + 多文档模型」

- 状态：已接受（2026-09-23）
- 背景：决策 D7 要求标签可拖出成独立窗口、可拖回合并。
- 决策：`Document` 是纯模型（文本/URL/编码/换行符/选区/滚动/独立 `UndoManager`/脏标记），不持有视图；每个窗口持一个 `EditorController`（单 `NSTextView`），切换标签时替换 `textStorage` 并绑定该文档的 `UndoManager`。标签迁移 = 文档对象在两个 `DocumentStore` 间移动。
- 代价：切换标签需妥善保存/恢复选区与滚动；实现复杂度高于「每标签一个视图」。
- 备选与否决理由：每标签一视图（内存与布局开销随标签数线性增长，且拖出成窗需重建视图）。

## ADR-006：颜色统一走 `EditorTheme` token 集合

- 状态：已接受（2026-09-23）
- 背景：S2 约束禁止散落颜色字面量，但本应用必须允许用户自定义编辑器配色。
- 决策：`EditorTheme` 定义全部语义 token（背景/前景/选中/查找高亮/光标/行号，亮暗两套），基线值存 Asset Catalog Color Set；用户覆盖值随 `AppSettings` 持久化，解析后注入 `EditorTheme`。视图与编辑器只消费 token，不出现颜色字面量。
