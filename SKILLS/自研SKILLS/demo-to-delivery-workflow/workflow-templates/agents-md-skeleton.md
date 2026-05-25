# AGENTS.md 五段式骨架 + docs/ 矩阵体例

> 本模板供 SKILL.md 步骤 7(文档体系生成)引用。新项目按此填模块级 `AGENTS.md` + `docs/` 矩阵。
>
> **数字阈值**:见 [`../SKILL.md`](../SKILL.md) "数字阈值单一来源" 块,本文件不重复声明。

---

## §0 项目级指令文件命名约定

<project_instruction_file_naming>

不同 AI 工具识别的"项目级指令文件"不同:

| AI 工具 | 主指令文件 | 备注 |
|---|---|---|
| **Claude Code** | `CLAUDE.md` | 仓库根优先;子目录 `<dir>/CLAUDE.md` 进入该目录时叠加 |
| **Cursor** | `.cursorrules` 或 `.cursor/rules/*.md` | |
| **OpenAI Codex / 跨厂规范** | `AGENTS.md` | 社区跨厂规范,正在逐渐通用化 |
| **Cline** | `.clinerules` 或 `CLAUDE.md` | |

**本工作流的实操约定**(由项目根据主用 AI 工具决定):

1. **主用 Claude Code 的项目**(本仓库属于这类):**主文件用 `CLAUDE.md`**,内容指向 `AGENTS.md`(跳转表)— Claude Code 加载 `CLAUDE.md` → 看到 "see AGENTS.md" → Claude Code 不会自动 Read AGENTS.md 但人类 AI 协作时会读
2. **主用 OpenAI Codex 的项目**:主文件用 `AGENTS.md`,可选额外建 `CLAUDE.md` 转发
3. **多 AI 兼容**:`CLAUDE.md` + `AGENTS.md` 同时存在,内容完全相同(或一份转发另一份)

本仓库 `CLAUDE.md` 实际是简短引用,真正内容在 `AGENTS.md`(详见 `CLAUDE.md`)。

</project_instruction_file_naming>

---

## §1 AGENTS.md 五段式骨架(模块级,≤ `agents_md_loc_budget`)

每个独立模块根目录放一份 `AGENTS.md`(或 `CLAUDE.md`,根据 §0 决定),作为"AI 协作入口"。结构如下;**`<agents_md_template_example>` 标签内是给人类用户复用本工作流时照抄填空的模板,不是给模型的直接指令** — 模型不应当 echo 这段内容到自己的输出:

<agents_md_template_example purpose="copy_paste_template">

```markdown
# <模块> Agents 导航

> 给协作 AI / 改代码的人用的索引。**只放"哪里看"**,机制细节留在代码 docstring。
> 项目介绍 / 运行环境 → [README.md](README.md);测试基建 → [tests/README.md](tests/README.md);配置字段 → [docs/config.md](docs/config.md)。

> **🚨 开篇必读(高频流程浓缩,§5 维护契约的浓缩版,≤ 5 条)**
> - <高频流程 1,比如 "git commit 前把'做了什么/验证结果'追加到 docs/changelog.md 顶部">
> - <高频流程 2,比如 "本次不做但要做的 → 记 docs/todo.md">
> - 其它(新增模块同步索引表 / 版本发布 / 行数预算等)见 §5

---

## 1. 功能 ↔ 代码索引表

| 功能 | API/主入口 | service/hook | model | schema | 测试入口 |
|---|---|---|---|---|---|
| <功能 1> | `<api 路径>` | `<service 路径>` | `<model>` | `<schema>` | `tests/docs/<功能>.md` |
| ... | ... | ... | ... | ... | ... |

新增功能模块 → 在本表加一行(不在代码里悄悄加)。

---

## 2. 各领域编码红线

每条 1~3 行,只说约束,机制细节请直接看对应 docstring。

- **<领域 1>**:<约束 1>(<典型反例>)
- **<领域 2>**:<约束 2>(<典型反例>)
- ...

(领域典型清单,按项目类型挑用:api / service / db / 租户 / models / schemas / tasks / 审计 / 历史 / 配置 / tests / 类型单一来源 / queryKey 工厂 / 状态分层 / selector / Tailwind / 错误处理 / 时间显示)

---

## 3. 必看 utility 速查

只列文件 + 一句话;改代码前先翻一遍,避免重复造轮子。

- `<utility 文件路径>` — <一句话用途>
- ...

新增 utility → 在本节加一行。

---

## 4. 测试定位

按 bug 症状查测试 → 直接跳 [tests/README.md](tests/README.md) 或 [tests/docs/](tests/docs/):

- 列出 tests 入口文件 / 按业务功能切片的命名 / 测试金字塔分层
- 本文件不复述"具体症状 → doc 的映射"(避免双写漂移)

---

## 5. 维护契约

- git commit 前:把"做了什么 / 验证结果"追加到 [docs/changelog.md](docs/changelog.md) 顶部(日期倒序)
- 本次不做但要做的:记入 [docs/todo.md](docs/todo.md) 对应优先级 / 模块(不只留在对话或代码注释里)
- 新增功能模块:同步 §1 索引表加一行;新增 utility → §3 加一行
- 版本发布:在 [docs/releases.md](docs/releases.md) 顶部追加一节;changelog 同日记一条"发布 vX.Y.Z"
- 本文件行数预算:≤ `agents_md_loc_budget`(默认 300);超出 → 先压缩或下沉到 `tests/docs/` / `docs/<功能>.md`,或拆出 `functions-index.md` / `coding-rules.md` 分文件
- 用户主动要求 review 时:对照 [docs/reviewRule.md](docs/reviewRule.md) 跑 P0 / P1 区域,产出分级 issue 列表交用户逐条确认;不据此自动改代码
```

</agents_md_template_example>

---

## §2 顶层 vs 模块级 AGENTS.md 分工

**顶层 `AGENTS.md`(仓库根)**:只放跳转表,**不写规则 / 红线 / 测试导航**(避免双写漂移)。

```markdown
# AGENTS.md — 仓库入口导航

> 本文件是 AI 进入仓库的第一站。**只放跳转表**,不写规则 / 红线 / 方法定位 / 测试导航 —— 这些都在子模块 AGENTS.md 里。

## 1. 项目速览
- **业务**:<一句话>
- **形态**:<前后端分离 / 单体 / CLI / ...>

## 2. 模块入口

| 模块 | AI 协作入口(必读) | 项目说明 / 启动 |
|---|---|---|
| <模块 1> | [`<模块>/AGENTS.md`](<模块>/AGENTS.md) | [`<模块>/README.md`](<模块>/README.md) |
| ... | ... | ... |

> 子模块 AGENTS.md 已包含:**功能↔代码索引、编码红线、utility 速查、测试定位、维护契约**。
> **本文件不再重复**,避免双写漂移。
```

**单模块项目**:可省顶层 AGENTS.md,模块级 AGENTS.md 上提到根目录;或顶层 AGENTS.md 与模块级 AGENTS.md 合并。

---

## §3 docs/ 矩阵骨架

每个模块 `docs/` 下固定文档(按项目复杂度按需裁剪):

| 文档 | 用途 | 体例 | 必需性 |
|---|---|---|---|
| `changelog.md` | 改动日志 | 日期倒序 + 条目结构(背景 / 改动清单 / 影响面 / 验证) | **必需** |
| `reviewRule.md` | review checklist | P0/P1/P2 + grep 快扫 + 输出模板 | **必需**(用户主动要求 review 时引用) |
| `config.md` | 配置字段表 | 字段名 / 类型 / 默认值 / 优先级 / 各环境实际值 / 强校验 | 后端 / 配置复杂项目 必需 |
| `releases.md` | 版本发布记录 | 倒序版本号 + 改动摘要 + 升级指南 | 长期演进项目必需 |
| `todo.md` | V2 backlog | P1/P2 优先级 + 触发条件 | **必需** |
| `<资产穷举索引>.md` | 资产名 → 位置反查 | 见 §4 资产穷举索引 | 复杂前端 / 类型复杂项目推荐 |

---

## §3.1 changelog.md 体例

日期倒序,每条独立可追溯。条目结构:

```markdown
## 2026-MM-DD <一句话主题>

**背景**:<为什么改 / 触发问题>

**改动**:
- <改动 1>:<具体文件:行>
- <改动 2>:...

**影响面**:<谁被影响 / 是否破坏性>

**验证**:<跑了哪些测试 / curl / grep 命中>
```

---

## §3.2 reviewRule.md 体例

P0 / P1 / P2 分级:

- **P0** = 数据正确性 / 服务起不来 / 编码出 bug(commit 前必修)
- **P1** = 返工 / 一致性 bug(不阻塞 commit 但应同 PR 内修)
- **P2** = 后续优化(记入 docs/todo.md,不强制本 PR 修)

每条 issue 含:`文件:行 + 现状 + 修法 + 影响面 + [Pass N 溯源]`(详见 `review-output-template.md`)

**reviewRule.md 输入来源决策表(增量 vs 重写)**:

| 项目入口形态 | reviewRule 生成方式 |
|---|---|
| **A. 新建项目** | 机械抽取:从 `archive/plans/LOG.md` + `IMPLEMENTATION-NOTES.md` + `archive/plans/archive/REVIEW-*.md` 抽取;每条 P0/P1 grep 反例文件命中 ≥ 1;通用 best practice(本项目未踩过)标记移除 |
| **B. 维护性项目** | 追加:基于本次增量的新 LOG/NOTES/REVIEW 追加;不重写已有 P0/P1;以日期分段标注(如 `## 2026-05-13 追加 P0(基于 V1.5 增量)`)|
| **C. V2 增量** | 追加:同 B;以版本/日期分段;V1 reviewRule 保留 |
| **D. PoC 探索** | 进入工程模式后才生成(探索期不写 reviewRule)|

---

## §3.3 其余 docs/ 文档体例(简表)

- `config.md`:每字段一行表格(字段名 / 类型 / 默认值 / 三档实际值 / 强校验);后端项目必需;前端 PoC / 简单项目可省
- `releases.md`:倒序版本号;每条目含改动摘要 + 升级指南 + 破坏性变更标记
- `todo.md`:按 P1 / P2 / P3 优先级分组;每条目含触发条件 / 估时 / 责任人

---

## §4 资产穷举索引(可选,复杂前端 / 类型复杂项目推荐)

**价值**:AI 改代码按"资产名"反查比按"业务功能"快。

典型 4 类(以本项目前端为例):

| 索引文件 | 内容 |
|---|---|
| `zod-fallback.md` | 类型兜底:列出每个端点的 zod schema + 兜底字段(每条 grep 命中证据)|
| `design-tokens.md` | Tailwind @theme 全 token 索引 + Phase 双轨配色 + 装饰元素清单 |
| `components-index.md` | 组件穷举:文件 / props / 关联 hook / data-test / spec(每行一组件)|
| `hooks-index.md` | hook 穷举:queryKey / endpoint / invalidate 链路 / spec(每行一 hook)|

资产穷举索引行数预算:每份 ≤ `asset_index_loc_budget`(默认 300);超出按模块拆。

---

## §5 行数预算 + 维护契约

| 文档 | 行数预算 | 超出处理 |
|---|---|---|
| `AGENTS.md` / `CLAUDE.md` | ≤ `agents_md_loc_budget`(默认 300)| 拆出 `functions-index.md` / `coding-rules.md`,本文件保留跳转 |
| `reviewRule.md` | ≤ `review_rule_loc_budget`(默认 200)| 压缩 §5 grep 快扫命令 或 拆 P0/P1 分文件 |
| `changelog.md` | 无限制 | 日期倒序,旧条目可压缩到月度摘要 |
| `资产穷举索引` | 每份 ≤ `asset_index_loc_budget`(默认 300)| 按模块拆 |

**维护契约**:
- 任何代码改动 → commit 前更新 `changelog.md` 顶部
- 新增功能模块 → AGENTS.md §1 索引表加行
- 新增 utility → AGENTS.md §3 加行
- 新增配置字段 → `config.md` 加行 + envs/*.env 三份同步
- 版本发布 → `releases.md` 顶部追加 + changelog 同日记 "发布 vX.Y.Z"

---

## §6 大型企业项目多模块 PROGRESS 分层指南

当项目跨多模块 / 多团队 / 多 repo 时,单一 PROGRESS.md 不够。分层方案:

```
仓库根/
├── PROGRESS.md          # 主 PROGRESS:全局状态 + 各 sub-PROGRESS 链接 + 跨模块阻塞
├── <模块 1>/
│   ├── PROGRESS.md      # sub-PROGRESS:本模块阶段状态 + 本模块产物索引
│   └── ...
├── <模块 2>/
│   ├── PROGRESS.md      # sub-PROGRESS
│   └── ...
```

**主 PROGRESS 含**:
- 全局当前阶段(若所有模块在同一大阶段)
- 各 sub-PROGRESS 链接 + 各模块最新状态摘要(一句话)
- 跨模块阻塞(模块 A 等模块 B 的 X 产物)
- 跨模块契约对齐状态(API 端点 / DB schema / 消息格式)

**sub-PROGRESS 含**:
- 同标准 progress-template.md 的 §1-§6
- 顶部加 "向主 PROGRESS 汇报频率"(每阶段末 / 每周 / 每次重大决策)

**跨团队协作 review 视角**:除 L1 七维 review 外,加 "跨团队接口对齐 review" 视角(prompt 见 `review-agent-prompt.md` §3.8):
- 角色定位:跨团队接口对齐审计
- 必读:本模块契约 + 上下游模块契约
- 输出:契约不一致 issue 清单(端点 / 字段 / 时序 / 错误码)

---

## §7 范例(本项目实操)

本项目实际:
- 顶层 `AGENTS.md`(纯跳转表) + `CLAUDE.md`(内容指向 AGENTS.md)
- `backend/AGENTS.md` + `backend/docs/{changelog,reviewRule,config,releases,todo}.md`
- `frontend/AGENTS.md` + `frontend/docs/{changelog,reviewRule,releases,todo}.md` + 资产穷举索引 4 份(`zod-fallback / design-tokens / components-index / hooks-index`)

未做多模块 PROGRESS 分层(本项目单仓库前后端两模块,主 PROGRESS 单份足够)。
