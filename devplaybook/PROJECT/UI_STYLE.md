# TXTForMac 视觉设计规范（UI_STYLE）

> **用途**：项目视觉设计语言 —— 实现 UI 时对齐本规范，审查时核对（CODE-REVIEW Q3）。
> **与约束的分工**：CONSTRAINTS-STACK/macos.md 管"怎么取用"（token/系统样式），本文件管"用什么"（具体值）。
> 本文件为 S3 项目标准（永不覆盖）；由 macos profile 生成基线，项目在骨架上填充。

## 设计基调

**这是一款"消失的编辑器"**：窗口里主体就是文本，chrome（标签栏/状态栏/查找条）克制到近乎不可见，不与文本争视觉重量。

- 默认窗口 900×600，最小 480×320；窗口标题显示文件名（脏文档加「已编辑」）
- 正文区域无内边距外的装饰；分隔线用系统 `separator` 色，1px
- 工具栏仅保留最高频项（新建/打开/保存/查找），其余走菜单与快捷键

## 色彩体系（Asset Catalog Color Set）

| Color Set 名 | 亮色值 | 暗色值 | 用途/场景 |
|---|---|---|---|
| AccentColor | 跟随系统强调色 | 同左 | 主操作/选中态/光标 |
| EditorBackground | #FFFFFF | #1E1F22 | 编辑器正文背景 |
| EditorForeground | #1D1D1F | #E6E6E6 | 编辑器正文前景 |
| EditorSelection | AccentColor @ 18% | AccentColor @ 28% | 文本选区 |
| EditorCaret | #1D1D1F | #E6E6E6 | 光标（非聚焦时隐藏） |
| EditorLineNumber | systemGray @ 60% | systemGray @ 55% | 行号（非默认显示，可开关） |
| FindHighlight | #FFE066 @ 45% | #B8860B @ 45% | 查找匹配 |
| FindHighlightActive | AccentColor @ 35% | AccentColor @ 45% | 当前匹配项 |
| ChromeBackground | systemWindowBackground | 同左 | 标签栏/状态栏底色 |
| StatusText | systemSecondaryLabel | 同左 | 状态栏文字 |
| BannerWarning | systemYellow @ 12% | systemYellow @ 18% | 大文件警告条 |
| Divider | systemSeparator | 同左 | 分隔线 |

> 全部颜色必须走 Color Set / `EditorTheme` token（ADR-006），禁散落 `Color(red:)` / `NSColor(...)` / 十六进制字面量。
> 用户可在设置中覆盖编辑器相关 token；覆盖值同样经 `EditorTheme` 注入，UI 代码不感知来源。

## 字体层级

| 场景 | 用法 |
|---|---|
| 编辑器正文 | 用户可配字体（默认系统等宽 13pt，等宽开关默认开），字号存 `EditorTheme` 默认值而非视图字面量 |
| 标签标题 | `.callout`（系统样式）；激活态常规字重，非激活态次要色 |
| 状态栏 | `.caption` + `.monospacedDigit()` |
| 设置页标题 | `.headline`；说明文字 `.footnote` + 次要色 |
| 对话框/提示 | `.body` |

## 间距与圆角

| Token | 值 | 场景 |
|---|---|---|
| 间距-紧凑 | 6 | 状态栏内元素间隙、标签内边距 |
| 间距-标准 | 12 | 设置页控件行内边距、查找条内边距 |
| 间距-宽松 | 20 | 设置页分组间距 |
| 圆角-控件 | 6 | 按钮/输入框 |
| 圆角-面板 | 10 | 警告条/浮层 |

## 组件视觉规范

| 组件 | 默认态 | 禁用态 | 外观要点 |
|---|---|---|---|
| 标签项 | 背景透明，文字次要色 | — | 激活项：ChromeBackground 提升一档 + 1px 底部分隔线消失；宽度 90–200pt，超出省略中部 |
| 标签关闭按钮 | 悬停显示 `xmark` | 单标签时隐藏 | 12pt，命中区 20×20 |
| 状态栏 | 高 22pt，ChromeBackground | — | 左：行列/字符数；右：编码/换行符/缩放，点击编码与换行符为可点区域（悬停显示下划线） |
| 查找条 | 高 32pt，自右向左出现 | 无文档时隐藏 | 输入框 + 上一/下一/关闭 + 开关组；`Esc` 关闭并还焦点给编辑器 |
| 警告条 | BannerWarning 底色，圆角-面板 | — | 左侧 `exclamationmark.triangle`，右侧「以只读打开」/「仍然编辑」动作 |
| 设置行 | 标签左、控件右，行高 28 | 依赖项未满足时整行置灰 | 需要说明的项在下一行 `.footnote` |

## 材质与图标

- 系统材质：设置窗口用 `sidebar`；浮层（查找条拖出提示、警告）用 `regularMaterial`
- 图标：全部 SF Symbols（`doc.badge.plus`、`magnifyingglass`、`textformat.size`、`arrow.triangle.2.circlepath`、`checkmark.circle` 等），统一 13pt 正文级 / 16pt 工具栏级

## 动效节奏

| 场景 | 时长 | 曲线 |
|---|---|---|
| 查找条/警告条出现与消失 | 0.15s | easeOut |
| 标签切换 | 0.12s | easeInOut |
| 标签重排 | 0.2s | spring(response: 0.3) |
| 状态变化（保存指示） | 0.2s | default |

> 尊重「减弱动态效果」系统设置：开启时全部降级为无动画。

## 交互底线

- 全部可点元素有悬停反馈；全部操作有键盘等价物（参见 SPEC US-003）
- 焦点环用系统默认；编辑区始终是第一响应者（除查找条/转到行激活时）
- 破坏性操作（关闭脏文档、丢弃会话）一律三选或二次确认
