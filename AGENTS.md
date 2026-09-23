# TXTForMac 项目宪法 — 任何工具开工前必读

> macos技术栈 — 架构/常用命令见 `devplaybook/PROJECT/PROJECT_INFO.md`

## 模式选择（工具自动判断）

- 小修改（单文件 / <30 行 / 无新依赖 / 不跨模块）→ **Quick 模式**
- 完整任务（新功能 / 多文件 / 跨模块 / 改架构）→ **Full 模式**
- 用户明确说「快速修改 XX」→ Quick；说「执行 XX」→ Full；未说明 → 工具按规模判断

---

## Quick 模式（3 步）

1. `git pull` — 拿最新状态
2. 直接修改文件
3. `git commit + push` — 立即落盘（pre-commit/commit-msg hook 自动校验）

> 小修改也不绕过：pull + 提交 + hook 检查是底线。

---

## Full 模式（Spec-First 完整流程）

1. `git pull` → 读 `PROGRESS.md`（全局状态）→ 读 `devplaybook/PROJECT/ASSETS.md`（已有资产）
2. 需求 → load skill: `brainstorming` → 产出 `devplaybook/SPEC/SPEC.md`：
   - US-### 用户故事 + 可验证验收标准（模糊项标记 `[假设]` 待确认）
   - 拆解 T-### 任务 DAG（单任务 ≤1h / ≤5 文件 / ≤200 行，超出继续拆）
3. 架构取舍（多模块 / 有争议时）→ `devplaybook/SPEC/ADR.md` 追加 ADR-###
4. 执行 → load skill: `subagent-driven-development`
   - 多个独立子任务 → load skill: `dispatching-parallel-agents`（文件不重叠 → 并行；重叠 → 串行；子代理不直接 commit）
   - 每个 T-### 按顺序：
     a. 查 `devplaybook/PROJECT/ASSETS.md` 复用已有资产；无现成才新写（搜索路径记录到 ASSETS.md 新写区）
     b. TDD（RED→GREEN→REFACTOR）
     c. 完成后 → **必须 Read** `devplaybook/STANDARDS/NO-SHORTCUT-CONSTRAINTS.md` 逐项自检，勾选结果写入提交说明
     d. 更新 `devplaybook/SPEC/TRACE.md`（US-### → T-### → 实现文件 → 测试文件）
     e. 涉及 UI → **必须 Read** `devplaybook/PROJECT/UI_STYLE.md` 对齐视觉规范
5. 审查 → load skill: `requesting-code-review`（对照 `devplaybook/STANDARDS/CODE-REVIEW.md` + 已挂载栈审查，含自检勾选核对）
   - ✅ 通过 → 记录；❌ 违规 → 打回该子代理 → 修复 → 重审 → 循环至通过
   - 修复只处理指出的问题；3 轮未通过 → 上报协调者介入
6. 全部通过 → 全量 `devplaybook/check-constraints.sh` → 统一 commit + push（按 `devplaybook/PROJECT/COMMIT_GUIDE.md` 规范）
7. 更新 `PROGRESS.md`
8. 上下文吃紧 → 见下方「上下文管理」

---

## 上下文管理

**信号**（满足任一）：
- 对话中开始频繁重读同一批文件 / 早期指令被遗忘
- 任务进行超一半仍未完成

**处理**：
1. 将当前任务状态、进行中任务速写写入 `PROGRESS.md` 的「上下文重载信息」
2. `/compact`（或新开回合）
3. 重载：`PROGRESS.md` + 本文件 + 当前任务相关 `devplaybook/SPEC/` 文件

---

## 铁律

- 一次只允许一个工具在改（工具间串行）
- 改完必须提交，不留未提交状态
- 提交前必须过 check-constraints（hook 强制）+ 符合 COMMIT_GUIDE 格式（commit-msg hook 强制）
- 涉及服务器/部署/外部服务 → 先 Read `devplaybook/PROJECT/PROJECT_INFO.md`；密钥值只从环境变量/全局 credentials.md 取，禁止写入代码或任何项目文件
- 禁止占位符实现（TODO/stub/mock 数据），除非对应 TRACE.md 中已编号任务
- 写新代码前必查 ASSETS.md，禁止重复造轮子
- 审查用 `devplaybook/STANDARDS/CODE-REVIEW.md`；约束见 `devplaybook/STANDARDS/GLOBAL-CONSTRAINTS.md`；实现标准见 `devplaybook/STANDARDS/NO-SHORTCUT-CONSTRAINTS.md`

---

## 标准文件速查（按管理权分组）

### S1 统一标准（中央库唯一管理，symlink 只读，修改请改中央库）

| 文件 | 用途 |
|---|---|
| `devplaybook/STANDARDS/GLOBAL-CONSTRAINTS.md` | 不可违反的约束（C1-C9 通用工程标准） |
| `devplaybook/STANDARDS/CODE-REVIEW.md` | 代码审查清单（通用 + 审查流程） |
| `devplaybook/STANDARDS/NO-SHORTCUT-CONSTRAINTS.md` | 防简化契约 + 12 维深度清单（实现后必须逐项自检） |
| `devplaybook/check-constraints.sh` | 检查引擎（hook 自动执行） |

### S2 栈标准（随技术栈挂载，只读）

| 文件 | 用途 |
|---|---|
| `devplaybook/STANDARDS/CONSTRAINTS-STACK/<栈>.md` | 技术栈专属约束（如 flutter 的 Theme/i18n/导航/状态） |
| `devplaybook/STANDARDS/REVIEW-STACK/<栈>.md` | 技术栈专属审查项 |

### S3 项目标准（项目所有，永不覆盖）

| 文件 | 用途 | 违反后果 |
|---|---|---|
| `devplaybook/PROJECT/PROJECT_INFO.md` | 技术栈/常用命令/架构/服务器/API/凭据引用 | 部署接错 = 事故 |
| `devplaybook/PROJECT/UI_STYLE.md` | 视觉设计规范（色彩/字体/组件/动效） | UI 不对齐 = 打回 |
| `devplaybook/PROJECT/COMMIT_GUIDE.md` | 提交规范（默认=全局约定） | 格式违规 = 提交拦截 |
| `devplaybook/PROJECT/ASSETS.md` | 已有资产清单（防重复造轮子） | 重复造轮子 = 打回 |
| `devplaybook/SPEC/{SPEC,TRACE,ADR}.md` | 需求/追溯/架构决策 | TRACE 缺映射 = 拦截 |
| `PROGRESS.md` | 项目状态/任务队列/上下文重载 | — |
| `devplaybook/rules/local.conf` | 项目定制规则 + 指令行 | — |

> 锚点原则：S1/S2 为底线防护（涉及即必须 Read 全文），S3 为项目自主内容。

---

## 更新工作流

用户说「更新工作流」→ 运行 `devplaybook-update`（或 `--force` 强制），查看 CHANGELOG.md 差异。
单文件更新: `devplaybook-update <文件名>`。S1/S2 修改请改中央库（symlink 即时生效）；S3 永不覆盖（详见 README）。

---

## Superpowers 集成

技能文件: `~/.agents/skills/<名称>/SKILL.md`

| 触发 | 技能 |
|---|---|
| 方案确认 | `writing-plans` / `executing-plans` |
| 写功能/修 bug | `test-driven-development` |
| 开工需要隔离环境 | `using-git-worktrees` |
| 被打回时 | `receiving-code-review` |
| 提交前 | `verification-before-completion` |
| 分支完成时 | `finishing-a-development-branch` |

完整清单: `~/.agents/skills/`（流程内技能已内嵌于 Full 模式步骤）
