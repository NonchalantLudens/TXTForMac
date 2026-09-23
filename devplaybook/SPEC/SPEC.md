# TXTForMac 需求与任务计划（SPEC）

> **用途**：Full 模式的核心产物 —— 用户故事（US-###）+ 任务 DAG（T-###）同文件维护。
> **约束**：模糊项必须标记 [假设] 待确认；每个 T 任务 ≤1h / ≤5 文件 / ≤200 行，超出继续拆。
> 本文件为项目内容，update 永不覆盖。

---

## 〇、产品定义

**一句话**：在 macOS 上还原 Windows 记事本的全部能力，并补上 macOS 用户期待的标签页、会话恢复、右键新建与自动更新。

| 项 | 值 |
|---|---|
| 应用名 | TXTForMac |
| Bundle ID | `online.nonchalantludens.txtformac`（扩展 `.finder`、测试 `.tests`） |
| 仓库 | `https://github.com/NonchalantLudens/TXTForMac` |
| 许可 | MIT |
| 最低系统 | macOS 15.0 Sequoia（[决策 2026-09-23]） |
| 技术栈 | Swift 6 / SwiftUI 外壳 + AppKit `NSTextView`(TextKit 2) 内核；无第三方运行时依赖（仅 Sparkle 用于更新） |
| 分发 | GitHub Releases：ZIP（供 Sparkle）+ DMG（供人装）；ad-hoc 签名 + Sparkle EdDSA 校验；不做公证 |
| 界面语言 | English（基准）+ 简体中文 |

### 非目标（明确不做）

- 语法高亮（含 Markdown）、代码补全、多光标
- 无限行宽/超 100MB 可编辑、二进制文件编辑
- Mac App Store 上架与公证（无 Developer ID；链路已预留）
- 云同步、协作编辑

### 已确认决策（来源：2026-09-23 brainstorming 问答）

| # | 决策 | 取值 |
|---|---|---|
| D1 | 技术栈 | SwiftUI 原生 |
| D2 | 右键方案 | Finder Sync 扩展 + 监控目录；**另加**快速操作兜底 |
| D3 | 更新机制 | Sparkle 2 + GitHub Releases + gh-pages appcast |
| D4 | 命名 | TXTForMac / `online.nonchalantludens.txtformac` |
| D5 | 大文件 | ≤20MB 全功能；20–100MB 顶部警告；>100MB 只读 |
| D6 | 最低系统 | macOS 15.0 |
| D7 | 标签页 | 支持「拖出成新窗口 / 拖回合并」 |
| D8 | 增项否决 | 不做「新建并命名」弹窗、不做 Markdown 高亮 |

---

## 一、用户故事（US-###）

### US-001：打开任意编码的文本文件

- 角色：从 Windows 迁移过来的用户  目标：打开中文 txt 不乱码
- 验收标准：
  1. 打开 UTF-8（含/不含 BOM）、UTF-16LE/BE、GB18030/GBK、Big5、Shift-JIS、Latin-1 文件，正文正确显示
  2. 无 BOM 的纯中文文件能被自动判定为 GBK/GB18030 而非拉丁乱码
  3. 状态栏显示识别出的编码，用户可手动指定编码并「重新打开」
  4. 拖放文件、Finder 双击、右键「打开方式」、`⌘O` 多选均能打开

### US-002：编辑保存后文件不损坏

- 角色：任意用户  目标：保存不改变原有编码与换行符
- 验收标准：
  1. 打开 GBK + CRLF 文件，仅改一个字符后保存，文件仍为 GBK + CRLF（字节级往返测试）
  2. 「另存为」可指定目标编码与换行符，并可选是否写 BOM
  3. 保存采用原子写（写临时文件 + 替换），中途失败不产生半截文件
  4. 开启备份时，保存前生成 `.bak`

### US-003：与 Windows 记事本对等的编辑能力

- 角色：习惯记事本的用户  目标：不用重新学操作
- 验收标准：
  1. 新建/打开/保存/另存为/打印 快捷键齐全（`⌘N ⌘O ⌘S ⇧⌘S ⌘P`）
  2. 撤销重做、剪切复制粘贴删除全选、粘贴为纯文本可用
  3. 自动换行、字体（家族/字号/行距）、缩放（快捷键/滚轮/捏合）可用
  4. `F5` 插入时间日期，格式可配置
  5. 状态栏显示行、列、字符数、选中字符数、编码、换行符、缩放

### US-004：查找、替换、转到行

- 角色：任意用户  目标：在大文件里快速定位与批改
- 验收标准：
  1. `⌘F` 增量查找，实时高亮并定位；支持区分大小写、全词、循环查找
  2. `⌘H` 替换：替换、替换并查找、全部替换；支持正则（含捕获组引用）
  3. `⌘L` 转到指定行，非法输入给出友好提示而非报错堆栈
  4. 查找栏可 `Esc` 关闭并把焦点还给编辑器

### US-005：多标签多文档

- 角色：同时开多个 txt 的用户  目标：一个窗口管多份文档
- 验收标准：
  1. `⌘T` 新建标签、`⌘W` 关闭当前标签（脏文档先询问）、中键关闭、`⌘1…9` 切换
  2. 标签可拖拽重排；可拖出标签栏成为独立窗口；独立窗口的标签可拖回合并
  3. 每个标签独立保有自己的选区、滚动位置、撤销栈、编码、换行符状态
  4. 切换标签无可感延迟（≤100ms，常规大小文件）

### US-006：内容不丢

- 角色：任意用户  目标：崩溃/断电/误关都不丢字
- 验收标准：
  1. 自动保存按可配间隔与失焦触发，状态栏/标题显示保存状态
  2. 应用被强制退出后重开，未保存内容与打开过的标签全部恢复
  3. 关闭有未保存改动的窗口时提供「保存 / 不保存 / 取消」三选
  4. 会话数据损坏时不阻塞启动（降级为空会话并记录日志）

### US-007：完整的设置页面

- 角色：想按自己习惯调优的用户  目标：所有行为可配
- 验收标准：
  1. `⌘,` 打开设置窗口，分页：通用 / 编辑 / 文件 / 外观 / 右键集成 / 更新 / 关于
  2. 设置项覆盖 SPEC「设置项清单」全部条目
  3. 任一设置改动立即生效（不需重启）；持久化于 `~/Library/Application Support/TXTForMac/config.json`
  4. 配置文件损坏或字段缺失时回落默认值，不崩溃
  5. 「关于」页可查看版本、MIT 许可全文、仓库链接

### US-008：Finder 右键新建文本文件

- 角色：从 Windows 过来的用户  目标：右键就地新建 txt
- 验收标准：
  1. 在监控目录内右键，菜单**顶级**出现「新建文本文件」（标题可配）
  2. 新建文件使用配置的命名模板（默认「新建文本文件」「新建文本文件 2」…）与扩展名
  3. 命名冲突按配置策略处理：自动编号 / 追加副本 / 询问
  4. 可在设置中增删监控目录，改完无需重启 Finder 即生效
  5. 未纳入监控的目录，可从右键「快速操作 → 新建文本文件」兜底完成

### US-009：自动更新

- 角色：已安装用户  目标：自动获得新版本
- 验收标准：
  1. 应用菜单「检查更新…」可手动检查；设置 → 更新页可调频率与通道
  2. 发现新版本后应用内下载并安装，EdDSA 签名校验失败时拒绝安装并提示
  3. appcast 托管在 gh-pages，URL 永久稳定，不随 Release 更替失效
  4. 私钥不入库（仅存本机，权限 600）

### US-010：界面中英双语

- 角色：非中文用户  目标：界面语言可切换
- 验收标准：
  1. 全部用户可见文本走 String Catalog，零裸硬编码（含菜单、状态栏、错误提示、Finder 菜单）
  2. 设置 → 通用 可切「跟随系统 / English / 简体中文」，切换后立即生效
  3. 两种语言下无截断、无占位符残留

### US-011：开源可协作

- 角色：贡献者  目标：能克隆即构建
- 验收标准：
  1. README 双语说明功能、系统要求、安装、构建、常见问题（含首次启动 Gatekeeper 右键打开说明）
  2. `git clone` 后一条命令生成工程并构建（xcodegen + xcodebuild），无需额外配置
  3. MIT LICENSE、双语 CHANGELOG、CONTRIBUTING 齐备
  4. 提交历史符合 commit 规范，`git log` 可读

### US-012：轻量

- 角色：只想要个记事本的用户  目标：别占资源
- 验收标准：
  1. 冷启动到可输入 ≤0.5s（Apple Silicon，SSD）
  2. `.app` 体积 ≤5MB（不含 Sparkle 动态框架时以主二进制计，含则 ≤8MB）
  3. 打开 10MB 文件耗时可接受（≤1s），常驻内存无异常增长

---

## 二、设置项清单（US-007 的验收依据）

| 分组 | 设置项 |
|---|---|
| 通用 | 界面语言（跟随系统/English/简体中文）；启动行为（空白文档/恢复上次会话/最近文件）；默认新建文件名；默认扩展名；默认编码；默认换行符；设为默认文本编辑器 |
| 编辑 | 字体家族；字号；行距；Tab 宽度；软 Tab；自动缩进；默认自动换行；记住每文档缩放；粘贴去格式 |
| 文件 | 自动保存开关与间隔；关闭时保存会话；最近文件数量（0–20）；大文件警告阈值；只读阈值；生成 `.bak` 备份 |
| 外观 | 主题（跟随系统/浅色/深色）；编辑器字体是否用等宽；编辑器背景/前景/选中色（token 覆盖）；标签栏显示；状态栏默认显示 |
| 右键集成 | Finder 扩展总开关；监控目录列表（桌面/文稿/下载/自定义增删）；菜单标题；新建文件扩展名；模板内容；命名冲突策略；打开系统扩展设置 |
| 更新 | 自动检查频率（每天/每周/每月/从不）；立即检查；通道（稳定/预览）；当前版本与构建号 |
| 关于 | 版本、构建号、MIT 许可全文、仓库链接、第三方声明（Sparkle） |

---

## 三、架构约定

```
TXTForMac/                          # 仓库根
├── project.yml                     # xcodegen 工程定义（3 target）
├── TXTForMac/                      # 主 App target
│   ├── App/                        # @main、AppDelegate、菜单、窗口控制
│   ├── Models/                     # Document / DocumentStore / TextEncoding / LineEnding / AppSettings
│   ├── Services/                   # FileIO / EncodingDetector / SettingsStore / SessionStore / Updater
│   ├── Editor/                     # EditorController / TextEditorView / FindBar / GoToLineBar / StatusBar
│   ├── Tabs/                       # TabBarView / 拖拽与开窗逻辑
│   ├── Settings/                   # 设置窗口与各分页
│   └── Resources/                  # Assets.xcassets / Localizable.xcstrings / Info.plist
├── TXTForMacFinder/                # Finder Sync 扩展 target（薄，逻辑复用 Shared）
├── Shared/                         # 两 target 共用：FileNaming / SettingsSchema / LineEnding / TextEncoding
├── TXTForMacTests/                 # 单元测试
├── scripts/                        # release.sh、appcast 发布辅助
└── devplaybook/                    # 工作流（本套）
```

**硬性架构规则**（审查会卡）：

1. 依赖方向：`App → Settings/Tabs/Editor → Services → Models`，`Shared` 只能被依赖、不反向依赖任何 App 层。Finder 扩展不得 import 主 App 模块。
2. View 层（SwiftUI）零业务逻辑：文件 IO、编码判定、会话读写一律在 Services；View 只绑定 `@Observable` 模型。
3. 配置读写**只有一个入口** `SettingsStore`；Finder 扩展经 `Shared/SettingsSchema` 读同一份 JSON，禁止各自定义键名。
4. 主 App 与扩展**不使用 App Group**（见 ADR-002），靠 `~/Library/Application Support/TXTForMac/config.json` + `DistributedNotificationCenter` 通信。
5. 所有耗时 IO 离开主线程（`async` + `Task.detached`），UI 更新回 `@MainActor`。

---

## 四、任务 DAG（T-###）

### M0 基础设施

```
T-001(工程骨架) → T-002(静态检查) ─┐
                → T-003(双语骨架) ─┼→ M1
                → T-004(仓库文件) ─┘
```

### T-001：［CHORE］工程骨架（关联 US-012，约 60min）

- 步骤：写 `project.yml`（app / finder / tests 三 target，macOS 15.0 部署目标，`GENERATE_INFOPLIST_FILE=false`）；建目录骨架与 `.gitignore`；`xcodegen generate`；`xcodebuild` 通过并跑起空窗口
- 前置：—  后置：T-002、T-003、T-004
- 验收：`xcodebuild -scheme TXTForMac build` 成功；`open` 出空窗口；`.xcodeproj` 入库

### T-002：［CHORE］静态检查与提交流程验证（约 30min）

- 步骤：`brew install swiftlint swiftformat`；加 `.swiftlint.yml` / `.swiftformat`；接入 `devplaybook/rules/local.conf` 的 `@pretest`；确认 pre-commit / commit-msg hook 生效
- 前置：T-001  后置：全部任务
- 验收：违规代码能被 lint 拦下；一次合规提交通过 hook

### T-003：［CHORE］双语骨架与语言切换机制（关联 US-010，约 45min）

- 步骤：建 `Localizable.xcstrings`（en 基准 + zh-Hans）；实现 `LocalizationService`（读取设置 → 覆盖 `AppleLanguages` 并重建菜单）；一个样例文案双语可切
- 前置：T-001  后置：全部 UI 任务
- 验收：切换语言后样例文案实时变化；无裸字符串

### T-004：［CHORE］仓库配套文件骨架（关联 US-011，约 30min）

- 步骤：`LICENSE`(MIT)、`README.md`/`README.zh-CN.md` 骨架、`CHANGELOG.md`、`CONTRIBUTING.md`、`.gitignore`
- 前置：T-001  后置：T-048
- 验收：文件齐备且语言双语一致

### M1 编辑器内核

```
T-005(LineEnding)──┬→ T-008(读) → T-009(写) → T-015(打开/保存)
T-006(Encoding)──┬─┘                              ↑
                 └→ T-007(检测) ───────────────────┘
T-010(Document) → T-011(EditorController) → T-012(EditorView+窗口) ─┬→ T-013(菜单)
                                                                    ├→ T-014(状态栏)
                                                                    ├→ T-016(大文件)
                                                                    └→ M2
```

### T-005：［MODEL］LineEnding 检测与转换（关联 US-001/002，约 30min）

- 步骤：TDD —— 枚举 CRLF/LF/CR、从文本探测、统计混排、全量转换、显示名
- 前置：T-001  后置：T-008、T-009
- 验收：单测覆盖纯 CRLF/LF/CR 与混排；转换后不改变可见字符

### T-006：［MODEL］TextEncoding 模型（关联 US-001/002，约 40min）

- 步骤：TDD —— 枚举（UTF-8 / UTF-8 BOM / UTF-16LE / UTF-16BE / GB18030 / Big5 / Shift-JIS / Latin-1 / ASCII）、BOM 常量与探测、CFStringEncoding 互转、显示名与本地化名
- 前置：T-001  后置：T-007
- 验收：每种编码与 `String.Encoding` 双向映射正确；BOM 写入/剥离测试通过

### T-007：［MODEL］EncodingDetector 编码判定（关联 US-001，约 60min）

- 步骤：TDD —— 判定链：BOM 优先 → UTF-8 严格校验通过即 UTF-8 → 无 BOM 时对 GB18030/Big5/Shift-JIS/Latin-1 做双字节合法性 + 常用字频打分 → 置信度低于阈值回落 GB18030
- 前置：T-006  后置：T-008
- 验收：语料集（GBK 中文、Big5 繁体、Shift-JIS 日文、UTF-8、Latin-1）判定全部正确

### T-008：［SERVICE］FileIOService 读取（关联 US-001/012，约 50min）

- 步骤：TDD —— 读字节 → 判编码 → 解码 → 探测换行符 → 返回 `LoadedDocument`（文本/编码/换行符/是否 BOM/大小/分行级）；按大小给 `LoadPolicy`（normal/warn/readOnly）
- 前置：T-005、T-007  后置：T-009
- 验收：各类编码文件读取正确；阈值分级正确；IO 在后台线程

### T-009：［SERVICE］FileIOService 写入（关联 US-002，约 50min）

- 步骤：TDD —— 按目标编码编码（含 BOM 策略）→ 换行符归一 → 原子写（临时文件 + `replaceItemAt`）→ 可选 `.bak`；往返保真测试
- 前置：T-008  后置：T-015、T-030
- 验收：GBK+CRLF 文件改一字保存后字节对比仅该处变化；写失败不留半截文件

### T-010：［MODEL］Document 与 DocumentStore（关联 US-005/006，约 50min）

- 步骤：TDD —— `Document`（id/文本/URL/编码/换行符/BOM/脏标记/选区/滚动/独立 `UndoManager`/缩放）；`DocumentStore`（增删改序、当前标签、脏计数、重排、跨窗口迁移）
- 前置：T-001  后置：T-011
- 验收：单测覆盖脏标记、标签重排、跨窗口迁移后状态不丢

### T-011：［EDITOR］EditorController 编辑器内核（关联 US-005/012，约 60min）

- 步骤：`NSTextView` + TextKit 2 配置（关闭富文本/智能替换，保持纯文本语义）；`NSViewRepresentable` 宿主；切换文档时替换 textStorage 并绑定该文档的 `UndoManager`（经 `NSTextViewDelegate.undoManager(for:)`）
- 前置：T-010  后置：T-012
- 验收：切换两个文档后各自撤销栈独立；滚动/选区在切换往返后保留

### T-012：［EDITOR］编辑器视图与窗口（关联 US-003/006，约 50min）

- 步骤：SwiftUI 窗口承载编辑器 + 顶部占位（标签栏位置预留）；实现关闭拦截三选对话框；`windowWillClose` 落状态
- 前置：T-011  后置：T-013、T-014、T-016、M2
- 验收：手动验证三选对话框；取消关闭后窗口仍在

### T-013：［APP］主菜单与命令路由（关联 US-003，约 50min）

- 步骤：以 AppKit 构建主菜单（App/文件/编辑/格式/查看/窗口/帮助）+ SwiftUI Commands 绑定；每个菜单项指向 `CommandRouter` 单一入口；快捷键按 US-003 清单
- 前置：T-012  后置：T-023、T-044
- 验收：全部菜单项可点且行为正确；无空实现

### T-014：［UI］状态栏（关联 US-003，约 40min）

- 步骤：显示行/列、字符数、选中字符数、编码、换行符、缩放；点击编码/换行符可直接切换并即时转换；`@Observable` 数据源
- 前置：T-012  后置：M4、M5
- 验收：光标移动时行列实时更新；切换编码后文本与状态同步

### T-015：［FEAT］打开 / 保存 / 另存为（关联 US-002/003，约 60min）

- 步骤：三命令接线；另存为用 `NSSavePanel` accessoryView 提供编码/换行符/BOM 选择；打开时用「重新打开并指定编码」恢复被误判文件；最近文件记录
- 前置：T-009、T-012  后置：T-024、T-025
- 验收：US-002 全部验收标准通过；取消面板不留脏标记

### T-016：［FEAT］大文件降级（关联 US-012，约 40min）

- 步骤：按 `LoadPolicy` 显示顶部提示条（warn）或进入只读模式（readOnly，禁用编辑但保留查找/另存为）；阈值来自设置
- 前置：T-012  后置：—
- 验收：构造 30MB / 150MB 文件验证两种降级行为

### M2 编辑能力

```
T-012 ─┬→ T-017(查找) → T-018(替换)
       ├→ T-019(转行)
       ├→ T-021(字体) → T-022(缩放)
       └→ T-026(打印)
T-013 → T-023(自动换行/编辑菜单)     T-015 → T-024(最近文件)、T-025(类型注册/拖放)
T-032(设置存储，见 M3，建议紧随 T-004 完成) → T-020(时间日期)、T-021(字体)
```

### T-017：［FEAT］查找栏（关联 US-004，约 60min）

- 步骤：编辑器内嵌查找条 UI；增量搜索 + 高亮全部匹配；区分大小写/全词/循环三开关；`⌘F`/`Esc` 焦点管理
- 前置：T-012  后置：T-018
- 验收：US-004 验收 1、4 通过；空查询不误高亮

### T-018：［FEAT］替换与正则（关联 US-004，约 60min）

- 步骤：替换栏（替换 / 替换并查找 / 全部替换）；正则开关与捕获组 `$1` 替换；替换计数反馈；撤销可回退「全部替换」
- 前置：T-017  后置：—
- 验收：US-004 验收 2 通过；非法正则给出友好提示

### T-019：［FEAT］转到行（关联 US-004，约 30min）

- 步骤：`⌘L` 弹出输入条；行号越界/非数字 → 友好提示；跳转后选中该行并滚动居中
- 前置：T-012  后置：—
- 验收：US-004 验收 3 通过

### T-020：［FEAT］插入时间日期（关联 US-003，约 30min）

- 步骤：`F5` 插入当前时间日期；格式串存设置（默认 `yyyy/M/d HH:mm`）；走系统本地化格式化
- 前置：T-012、T-032  后置：—
- 验收：插入文本与配置格式一致；中英环境下格式正确

### T-021：［FEAT］字体设置（关联 US-003，约 40min）

- 步骤：`NSFontPanel` 接线（格式菜单「字体…」）；字体家族/字号/行距应用到编辑器；持久化
- 前置：T-012、T-032  后置：T-022
- 验收：字体改动即时生效并跨重启保留；默认等宽可选

### T-022：［FEAT］缩放（关联 US-003，约 40min）

- 步骤：`⌘+`/`⌘-`/`⌘0`、`⌘`+滚轮、触控板捏合；每文档记忆（可配）；状态栏联动；范围 50%–500%
- 前置：T-021  后置：—
- 验收：四种入口一致；缩放不影响文本内容与保存结果

### T-023：［FEAT］自动换行与编辑菜单补齐（关联 US-003，约 40min）

- 步骤：自动换行开关（视图菜单/格式菜单）；粘贴为纯文本；删除、全选、跳转菜单；编辑菜单项与响应链串联
- 前置：T-013  后置：—
- 验收：US-003 验收 2 通过；菜单在无文档时正确禁用

### T-024：［FEAT］最近文件（关联 US-003，约 30min）

- 步骤：记录最近打开（去重、上限来自设置）；菜单子项 + 「清除菜单」；文件不存在时标注并跳过
- 前置：T-015  后置：—
- 验收：上限与去重正确；清除生效

### T-025：［FEAT］文档类型注册与拖放打开（关联 US-001，约 40min）

- 步骤：Info.plist `CFBundleDocumentTypes`（public.plain-text / .txt / .md / .log / .csv 等，Editor 角色）；`onOpenURL`/`application(_:open:)` 接线；编辑器拖放；多选开多标签
- 前置：T-015  后置：—
- 验收：Finder 双击与拖放均按配置开新标签；未知二进制文件给出友好提示

### T-026：［FEAT］打印与页面设置（关联 US-003，约 40min）

- 步骤：`NSPrintOperation`（页眉页脚、行号可选）；`⌘P` / 页面设置；与缩放/自动换行协作正确
- 前置：T-012  后置：—
- 验收：打印预览分页正确；中文不乱码

### M3 标签页与会话

```
T-012 → T-027(标签栏) → T-028(重排) → T-029(拖出/合并)
T-009、T-027 → T-030(自动保存) → T-031(会话恢复)
T-032(设置存储) 独立（建议紧随 T-004 执行），M2 的 T-020/T-021 与 M4/M5 全部依赖
```

### T-027：［FEAT］标签栏（关联 US-005，约 60min）

- 步骤：`TabBarView`（显示脏标记、关闭按钮、溢出滚动）；`⌘T`/`⌘W`/中键关闭/`⌘1…9`；当前标签高亮
- 前置：T-012  后置：T-028、T-030
- 验收：US-005 验收 1、3 通过

### T-028：［FEAT］标签拖拽重排（关联 US-005，约 45min）

- 步骤：拖拽重排（含拖拽指示线）；`DocumentStore` 顺序落盘；重排不影响文档状态
- 前置：T-027  后置：T-029
- 验收：US-005 验收 2（重排部分）通过

### T-029：［FEAT］标签拖出成窗口与合并（关联 US-005，约 60min）

- 步骤：拖出标签栏 → 新建窗口并迁移文档；独立窗口标签拖回 → 合并；无窗口时自动出现空白窗口
- 前置：T-028  后置：—
- 验收：US-005 验收 2 全部通过；迁移后撤销栈与脏状态保持

### T-030：［FEAT］自动保存（关联 US-006，约 50min）

- 步骤：定时 + 失焦触发保存（可达才保存，未命名文档存会话）；保存状态指示；`⌘S` 与自动保存并发时无竞态
- 前置：T-009、T-027  后置：T-031
- 验收：长时间编辑内容已落盘；并发保存不丢字

### T-031：［FEAT］会话恢复（关联 US-006，约 60min）

- 步骤：周期性 + 退出时写入会话（标签、未命名内容、光标、滚动、编码、窗口几何）；启动按设置恢复；会话损坏降级为空会话并记日志
- 前置：T-030  后置：—
- 验收：`kill -9` 后重开内容仍在；损坏会话不影响启动

### T-032：［MODEL］SettingsStore 设置存储（关联 US-007，约 60min）

- 步骤：TDD —— `AppSettings`（Codable，覆盖设置清单全部项）；读写 `config.json`（原子写）；缺失/损坏回落默认；版本迁移；变更经 `DistributedNotificationCenter` 广播
- 前置：T-001（**建议紧随 T-004 执行**：M2 的 T-020/T-021 依赖它，且 M4/M5 全部依赖）
- 后置：M4 全部、M5 全部
- 验收：单测覆盖默认值、损坏文件、迁移；并发写不产生半截 JSON

### M4 设置页

```
T-032 → T-033(设置窗口+通用) ─┬→ T-034(编辑+外观)
                             ├→ T-035(文件)
                             ├→ T-036(默认编辑器)
                             └→ T-037(主题)
T-033..T-037 → T-038(文案全覆盖自检)
```

### T-033：［UI］设置窗口与通用页（关联 US-007，约 60min）

- 步骤：设置窗口（分页导航，`⌘,` 打开）；通用页（语言、启动行为、默认文件名/扩展名/编码/换行符）
- 前置：T-032  后置：T-034、T-035、T-036、T-037、T-041、T-045
- 验收：设置项即时生效并重启保留

### T-034：［UI］编辑页与外观页（关联 US-007，约 50min）

- 步骤：编辑页（字体/字号/行距/Tab/软 Tab/自动缩进/自动换行/缩放/粘贴去格式）；外观页（主题、等宽开关、标签栏与状态栏显示）
- 前置：T-033  后置：T-038
- 验收：各项即时生效

### T-035：［UI］文件页（关联 US-007，约 45min）

- 步骤：自动保存开关与间隔、关闭保存会话、最近文件数量、大文件阈值、只读阈值、备份开关
- 前置：T-033  后置：T-038
- 验收：阈值改动影响 T-016 行为

### T-036：［FEAT］设为默认文本编辑器（关联 US-007，约 40min）

- 步骤：`NSWorkspace.setDefaultApplication(at:toOpenFileAt:)`（macOS 12+）实现「设为默认文本编辑器」按钮；显示当前默认应用与结果反馈
- 前置：T-033  后置：T-038
- 验收：设置后 Finder 双击 .txt 用本应用打开

### T-037：［UI］主题与编辑器配色 token（关联 US-007/010，约 50min）

- 步骤：定义 `EditorTheme` token（背景/前景/选中/查找高亮/光标/行号，亮暗两套，放 Asset Catalog Color Set）；用户覆盖值存设置；主题切换跟随系统
- 前置：T-032、T-033  后置：T-038
- 验收：亮暗切换无遗漏；无散落颜色字面量

### T-038：［UI］文案全覆盖自检（关联 US-010，约 40min）

- 步骤：扫描全部用户可见字符串（菜单/状态栏/对话框/错误/设置/Finder 菜单）→ 迁入 String Catalog；中英各跑一遍全流程检查截断
- 前置：T-033…T-037  后置：—
- 验收：US-010 验收 2、3 通过；grep 无裸中文/英文界面文案

### M5 Finder 集成

```
T-032 → T-039(扩展骨架) → T-040(右键新建) ─┬→ T-041(设置页 pane) → T-043(热重载)
                                          └→ T-042(快速操作兜底)
```

### T-039：［FEAT］FinderSync 扩展骨架（关联 US-008，约 60min）

- 步骤：`TXTForMacFinder` target（Info.plist `NSExtensionPointIdentifier=com.apple.FinderSync`）；`FIFinderSync` 子类；从设置读取监控目录并 `FIFinderSyncController.default().directoryURLs`；统计上报交给 App
- 前置：T-032、T-001  后置：T-040
- 验收：扩展被系统识别并出现在「登录项与扩展」；设置目录后 `directoryURLs` 同步

### T-040：［FEAT］右键新建文本文件（关联 US-008，约 60min）

- 步骤：TDD（共享 `FileNaming`：模板、序号、冲突策略）→ 菜单顶级项 + 子菜单；点击后在目标目录落盘（用配置的模板内容与编码）并通知主 App 打开
- 前置：T-039  后置：T-041、T-042
- 验收：US-008 验收 1、2、3 通过；中文文件名正确

### T-041：［UI］设置页右键集成（关联 US-008，约 50min）

- 步骤：扩展总开关、监控目录增删（桌面/文稿/下载快捷加）、菜单标题、扩展名、模板内容、冲突策略、跳转系统扩展设置的引导按钮；扩展未启用时给出明确指引
- 前置：T-040、T-033  后置：T-043
- 验收：US-008 验收 4 通过

### T-042：［FEAT］快速操作兜底（关联 US-008，约 40min）

- 步骤：Info.plist `NSServices`（接收 `public.folder`）；主 App 启动注册 `servicesProvider`；处理函数新建文件；对未监控目录也可用
- 前置：T-040  后置：—
- 验收：US-008 验收 5 通过

### T-043：［FEAT］配置热重载（关联 US-008，约 40min）

- 步骤：扩展端监听 `DistributedNotificationCenter` + 按 `config.json` mtime 校验；变化后重建菜单与 `directoryURLs`，不重启 Finder
- 前置：T-041  后置：—
- 验收：改设置后在 Finder 右键立即反映新标题/目录

### M6 更新与发布

```
T-044(Sparkle) → T-046(密钥) → T-047(发布脚本) → T-048(文档) → T-049(发布)
T-045(更新页/About/图标) ← T-044、T-033
```

### T-044：［FEAT］Sparkle 接入（关联 US-009，约 50min）

- 步骤：SPM 引入 Sparkle 2；`SPUStandardUpdaterController`；Info.plist `SUFeedURL`（gh-pages）/`SUPublicEDKey`/`SUEnableAutomaticChecks`；应用菜单「检查更新…」；设置中的频率与通道映射到 Sparkle 参数
- 前置：T-013  后置：T-045、T-046
- 验收：本地伪造 appcast 能触发「已是最新」；签名校验路径可跑通

### T-045：［UI］更新页、关于页与应用图标（关联 US-009/011/US-007，约 50min）

- 步骤：更新页（频率/立即检查/通道/当前版本）；关于页（版本、MIT 全文、仓库链接、Sparkle 声明）；应用图标各尺寸入 Assets
- 前置：T-044、T-033  后置：T-048
- 验收：US-007 验收 5 通过；图标在 Dock/Finder 正常

### T-046：［CHORE］EdDSA 密钥生成与保管（关联 US-009，约 30min）

- 步骤：生成 Sparkle 密钥对；公钥写入项目；私钥移至本机 `~/.config/txtformac/`（权限 600）并登记到 PROJECT_INFO 引用名；验证仓库无泄漏
- 前置：T-044  后置：T-047
- 验收：US-009 验收 4 通过；`git grep` 无私钥

### T-047：［CHORE］发布脚本 release.sh（关联 US-009，约 60min）

- 步骤：`xcodebuild archive` → 导出 app → ad-hoc 签名 → ZIP + DMG → `sign_update` 生成 EdDSA 签名 → 更新 `appcast.xml` → `gh release create` → 推送 gh-pages
- 前置：T-046  后置：T-049
- 验收：一条命令产出可分发产物与更新后的 appcast

### T-048：［DOC］README 与发布文档（关联 US-011，约 50min）

- 步骤：双语 README（功能、要求、安装、构建、FAQ 含首次启动 Gatekeeper 说明）；CHANGELOG v1.0.0；CONTRIBUTING（含 devplaybook 流程）
- 前置：T-047  后置：T-049
- 验收：US-011 验收 1、2、3 通过

### T-049：［RELEASE］仓库上线与 v1.0.0 发布（关联 US-009/011，约 45min）

- 步骤：`gh repo create NonchalantLudens/TXTForMac --public`；首推 main → 建 `feature/*` 分支流程确认 → 合并 → 打 tag `v1.0.0` → 跑 release.sh → 装 v1.0.0 → 用 v0.9.9（本地改版本号伪造）验证自动更新端到端
- 前置：T-048  后置：—
- 验收：US-009 验收 2、3 通过；仓库可公开访问且 README 渲染正常

---

## 五、里程碑验收门

| 里程碑 | 通过条件 |
|---|---|
| M0 | 空工程可构建可运行；CI 级静态检查零 error |
| M1 | 手动打开 GBK/UTF-8/UTF-16 中文文件正确显示；保存往返字节级对比仅改动处不同 |
| M2 | 与 Windows 记事本逐项对照清单全绿（见 US-003/004 验收） |
| M3 | `kill -9` 后重开内容完整恢复；标签拖出/合并无状态丢失 |
| M4 | 设置项全量可用且即时生效；重启后保留 |
| M5 | 桌面/文稿右键顶级出现「新建文本文件」并正确落盘；非监控目录走快速操作可用 |
| M6 | 旧版本能自动检出并装上 GitHub Release 的新版本 |

## 六、风险与对策

| 风险 | 对策 |
|---|---|
| 未公证应用首次启动被 Gatekeeper 拦截 | README 明写右键打开；关于页给出指引 |
| Finder 扩展在未启用时不显示菜单 | 设置页检测扩展状态并给出逐步引导（T-041） |
| ad-hoc 签名下 Sparkle 校验行为 | 以 EdDSA 为安全边界，实测签名失败必须拒绝安装（T-049） |
| GBK/Big5/Shift-JIS 歧义误判 | 打分 + 置信度阈值 + 一键「重新打开并指定编码」（T-007/T-015） |
| NSTextView 大文件卡顿 | 三级降级（T-016），阈值可配 |
| 扩展与主 App 配置不同步 | 单一配置源 + 通知 + mtime 校验（T-043） |
