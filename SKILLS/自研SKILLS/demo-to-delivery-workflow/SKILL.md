---
name: demo-to-delivery-workflow
description: >-
  通用项目工作流方法论 —— 把项目从 demo / 原型 / PoC 推进到工程化交付的 7 步闭环(demo 业务文档化 → plan 平行分解 → 多轮七维 review → 拆 IMPLEMENTATION → 分阶段实施 → demo 对比调优 → 文档体系生成),配套三层 review(L0 人工 + L1 agent + L2 sanity-scan)、PROGRESS.md 跨会话锚点、验收门双模板(代码型 / 文档型)、finding/filtering 两阶段评审。适用于需要"多阶段、跨会话、可控交付"的较大项目工程化。当用户要把一个 demo/PoC 工程化为正式产品、为一个新项目规划完整实施路线、对一份多维度 plan 做系统化设计评审、把一个较大需求拆成多个实施阶段并按验收门推进、跨会话续做一个长周期项目、或做 V2 增量 / 维护性增量时使用本 skill。不适用:单文件或单函数的代码评审、一次性小修改、纯知识问答 —— 这些用更轻量的工具(如 code-review)处理。
---

# 通用项目工作流(demo → 工程化交付)

> **本文件即 skill 入口(SKILL.md)**:总览 + 通用纪律。配套 [`steps/`](steps/)(7 步详述)+ [`workflow-templates/`](workflow-templates/)(模板套件)。
>
> **如何使用**:新会话进入工作流时,先读本文件 §0.1 的 Core 5 首读路径,再按当前所处步骤展开对应 `steps/stepN-*.md` 与模板。子文件中的 `../SKILL.md §X` 指针均指向本文件对应章节。
>
> **适用面**:任意类型项目(纯前端 SPA / 纯后端 / 全栈 / CLI / Lib / Notebook / 维护性增量 / V2 增量 / PoC 探索 / 多模块企业级)
>
> **方法论演进记录**(provenance,运行时无需读):见原始仓库 `WORKFLOWV2.v3/changelog.md` 与 `WORKFLOWV2.v3/CHANGES-V3.md`。

---

<recommended_runtime_config audience="human_operator">

## ⚙️ 配套 Claude Opus 4.7+(含 4.8)运行配置(强烈建议)

本工作流是 **long-horizon agentic 场景**(数周-数月跨多会话)。Claude Opus 4.7+(含 4.8)在此场景下的官方推荐配置:

- **effort**:`xhigh`(coding / agentic 首选)或 `max`(超长 horizon)。本工作流的"多 subagent 三层 review"在 `xhigh` 以下会被模型默认压制。**Opus 4.8 默认 effort=high**,用 4.8 跑长 horizon 仍建议显式调到 `xhigh`
- **thinking**:`{type: "adaptive"}`(自动按复杂度分配思考预算)
- **max_tokens**:≥ 64k(留够 subagent + tool call + thinking 的合并预算)
- **subagent 频次**:本工作流故意采用 **"用完即释放" 的多 subagent 模式**,理由见 §0.4 — 这是与 4.7+ 默认行为相反的有意设计,正文中已对每处 subagent 给出 Why

**Adaptive thinking 触发引导**(下面的 `<api_runtime_config>` 段是给**配置 Claude API system prompt 的人**复制粘贴用的,**不是给模型的直接指令** — 模型本身不应当 "应用" 这段,而是当它出现在 system prompt 时按其行为):

<api_runtime_config purpose="copy_to_system_prompt">

```
Adaptive thinking should be used when:
- 验收门失败的根因分析
- 路线级修订的影响面评估
- 多 Pass 七维 review 间的交叉冲突仲裁
- L1 review agent 报新 P0 是否真的阻塞下游的判断

Otherwise(执行 task / Edit / grep / 读文件 / 走 PROGRESS 唤醒指针),直接行动,不预思考。
```

</api_runtime_config>

</recommended_runtime_config>

---

<numeric_thresholds_single_source>

## ⚙️ 数字阈值单一来源(全工作流只在此声明一次)

所有数字阈值(子任务粒度、回环轮次、行数预算、阈值天数等)默认值集中于此;**新项目在 `PROGRESS.md` 顶部元信息中通过 `thresholds:` block 覆盖**;不强制照搬。其余文件**引用本表**,不重复声明。

| 阈值名 | 默认值 | 适用场景 |
|---|---|---|
| `task_granularity_per_stage` | 4–8 | 每阶段 TaskCreate 子任务数 |
| `stage_count_lightweight_threshold` | ≤ 4 | 触发"小项目降级" |
| `stage_loc_lightweight_threshold` | ≤ 200 | 单阶段代码行数,触发降级 |
| `plan_loc_lightweight_threshold` | < 200 | plan 文件行数,plan 自审降级 |
| `notes_writeback_trigger` | ≥ 10 条 | NOTES 触发 plan/IMPLEMENTATION 批量回写 |
| `loop_max_rounds` | ≤ 3 | 任一回环单条上限,触发 L0 拍板 |
| `agents_md_loc_budget` | ≤ 300 | AGENTS.md 行数;超出拆分 |
| `review_rule_loc_budget` | ≤ 200 | reviewRule.md 行数 |
| `asset_index_loc_budget` | ≤ 300 | 资产穷举索引每份行数 |
| `stale_warmup_milestone_days` | > 14 天 | 强制读里程碑层 |
| `stale_warmup_overview_days` | > 30 天 | 额外重读 plans/00-overview.md |
| `commit_per_stage` | 1–3 | 每阶段 commit 颗粒 |
| `doc_recon_diff_threshold` | 节点 × 10% 向上取整,最小 1 | 文档型验收门"反向重建测"的差异上限 |
| `loc_drift_threshold` | < 10% | 复制泛化场景的行数偏差 |
| `agent_prompt_target_words` | 风格指引(非硬上限) | review agent 输出参考字数,见 review-agent-prompt.md |

</numeric_thresholds_single_source>

---

## §0 适用范围 & 入口决策树 & 概念分层 & 运行机制

### §0.1 概念分层 + 首读路径(单一来源)

新会话进入工作流时,按以下分层 Read。**Core 5 个 = 首读必备 = 仅读这 5 个即可开工**;**Extended 13 个 = 实战触发时按需展开,不主动读**。

<core_concepts_first_read>

**Core 5(必读,即首读 3 模板的扩展版)**:

| # | 概念 | 一句话 | 必读位置 |
|---|---|---|---|
| C1 | 7 步流程 | demo → plan → review → 拆 IMPLEMENTATION → 实施 → demo 对比 → 文档体系 | 本文件 §1 + 当前步骤 `steps/stepN-*.md` |
| C2 | 三层 review(L0 人工 + L1 agent + L2 sanity-scan) | 每阶段末必跑,subagent 用完即释放,避免主对话上下文膨胀(详见 §0.4) | 本文件 §2 第 6 条 |
| C3 | 验收门双模板(代码型 5/6 + 文档型 5) | 验收门用具体 grep / 命令口令,失败即停 | [`workflow-templates/stage-template.md`](workflow-templates/stage-template.md) §0.3 |
| C4 | PROGRESS.md 跨会话锚点 + 5 唤醒分支 | 新会话首读;状态快照 + 唤醒指针,不写日志和决策 | [`workflow-templates/progress-template.md`](workflow-templates/progress-template.md) |
| C5 | review agent 6 槽位 prompt(XML 化) | 启动 subagent 必填 6 槽位,XML 包装减少误读 | [`workflow-templates/review-agent-prompt.md`](workflow-templates/review-agent-prompt.md) |

</core_concepts_first_read>

<extended_concepts_on_demand>

**Extended 13(实战触发时再读,不主动读)**:

| # | 概念 | 触发时刻 |
|---|---|---|
| E1 | demo 形态 4 变体(SPA / 后端 API / CLI / Notebook) | 步骤 1 开始时 |
| E2 | 4 种入口形态决策树(新建 / 维护 / V2 / PoC) | 项目开始时拍板(§0.2) |
| E3 | 跨模块/跨进程契约对齐(验收门第 6 项) | 多模块 / 跨进程项目 |
| E4 | 反向重建测(文档型验收门) | 步骤 1 / 3 / 7 文档型阶段 |
| E5 | sanity-scan agent(修订后) | 任何修订后 |
| E6 | reviewRule 输入来源约束(机械抽取 LOG/NOTES/REVIEW) | 步骤 7 |
| E7 | 小项目降级 + plan 自审降级 | 阶段 ≤4 / plan < 200 行 |
| E8 | 多 AI 接手协议 + 长期续做里程碑层 | 跨会话 / 跨 AI(§5) |
| E9 | NOTES → plan + IMPLEMENTATION 反向同步 | 实施期发现 plan 不一致 |
| E10 | 反问钩子开头 + 中段触发器 | 阶段开始 + 实施期遇模糊 |
| E11 | 回环退出 ≤ 3 轮 | 同一回环超过 3 轮 |
| E12 | seven-dim review 7 个 pass | 步骤 3 多轮 review |
| E13 | finding / filtering 两阶段 review(L1 → L0) | 任何 review 启动时 |

</extended_concepts_on_demand>

### §0.2 入口形态决策树

```
开始 → 项目是什么形态?
│
├── A. 新建项目 + 已有 demo
│   → 7 步全跑(完整模式)
│   → 步骤 1 必跑(demo 文档化三件套)
│   → 步骤 6 必跑(demo 对比调优)
│
├── B. 维护性项目(已有大型代码库,加 1 个小功能)
│   → 跳步骤 1(无新 demo,业务说明从已有 docs / AGENTS.md 抽)
│   → 步骤 2 plan 简化(只覆盖增量维度)
│   → 步骤 6 可省(已有代码库无对照 demo)
│   → 步骤 7 reviewRule 追加(以日期分段)
│
├── C. V2 增量(已有 V1 完整产物)
│   → 步骤 2 plan 增量重跑(只新维度 + 受影响 V1 维度)
│   → **重跑 plan 自审**
│   → 七维 review 仅跑维度影响图覆盖到的 pass(局部 review)
│   → PROGRESS.md 续用,V1 NOTES/LOG 归档到 archive/v1/
│   → reviewRule.md 追加(以日期分段)
│
└── D. PoC 探索(不知道最终形态,边试边调整)
    → "探索模式":步骤 2-5 快速循环,不强制 review
    → 稳定后切回"工程模式":跑 plan 自审 + 完整 7 步
    → PROGRESS.md 顶部标注"工程模式 / 探索模式"
```

### §0.3 运行机制

<progress_md_mechanism>

**PROGRESS.md(跨会话锚点)**:

- 实施期生成于仓库根 `PROGRESS.md`
- 新会话第一动作 Read;按"动态唤醒指针"按当前阶段分支继续 Read 上下文
- **更新时机**:每阶段末尾 + 每对话结束前 + 阻塞出现时 + 中段反问触发时
- 长期续做:`> stale_warmup_milestone_days` 读里程碑层;`> stale_warmup_overview_days` 额外重读 `plans/00-overview.md`
- 模板:[`workflow-templates/progress-template.md`](workflow-templates/progress-template.md)

</progress_md_mechanism>

<commit_mechanism>

**Commit 由人工触发(机制层,非 prompt 层约束)**:

本工作流 **不通过 prompt 约束 Claude 不要 commit**;真正的拦截发生在 **`.claude/settings.json` 的 PreToolUse hook**,拦截以下命令集合:

```
git commit / git commit --amend / git tag -a / git rebase -i
gh pr merge / git merge --no-ff / git push
```

实施期流程:
1. AI 完成阶段任务 + stage changes(`git add <files>`)
2. AI 在 PROGRESS.md §1 列 "staged 文件清单" + 提示 "本阶段已可 commit"
3. **commit message 由用户撰写**(prefix 参考见 [`stage-template.md`](workflow-templates/stage-template.md) §1.5)
4. 用户手动敲 `git commit`,hook 不会拦截(因为是用户主动调用,hook 设计为只拦截 AI 调用)

**为什么是 hook 而非 prompt**:Prompt 约束在 4.7+ 字面化下虽会被遵守,但模型理解的"自动"与用户期望的"自动"边界不同(例如"用户说 commit 一下"算不算自动?);hook 是唯一可靠的强制层。

</commit_mechanism>

<multi_ai_handover>

**多 AI 协作**:接手人按 PROGRESS.md §5 接手分支指针 Read 上下文 + 提示用户是否需要跑 1 个 agent 增量 sanity-scan(用户拍板,不自动启动);不重跑 plan 自审(详见 [`references/handover-and-longrun.md`](references/handover-and-longrun.md))。

</multi_ai_handover>

### §0.4 为什么本工作流故意使用多 subagent(给 Claude 4.7+ 的解释)

Claude Opus 4.7+ 默认行为是**减少 subagent 使用**,倾向用主对话 reasoning 完成。本工作流刻意采用相反策略:

<why_multi_subagent>

**理由 1 — Review 质量需要独立视角**

主对话累积了 plan 设计意图 + 用户偏好 + 已修订理由 → reviewer 视角被这些信息污染,出现"echo chamber":主对话认为"已经修对了"的 review 也认为对。**用 subagent + 槽位 2 `<must_not_read>` 隔离主对话,才能真正独立 review。**

**理由 2 — 主对话上下文预算管理**

7 步流程跨数周/数月,主对话累积上下文容易超过 200k token。**Subagent 用完即释放**(返回 ≤ 2000 字结论),不污染主对话。

**理由 3 — 高风险节点的交叉验证**

数据模型 / API 契约 / 跨模块对齐错误代价极高。**2 个独立视角 agent 的 finding 重叠度低**(经验值 < 40%),显著提升 recall。

**因此,本工作流中每处出现 "启动 N 个 subagent" 都是有意为之**;请按 Why 注释执行,不要降级为单 agent 或主对话 reasoning。

</why_multi_subagent>

---

## §1 总览表

| 步骤 | 一句话目标 | 详述 | 核心产物 | 进入下一步硬条件 | 验收门类型 | 入口适配 | 参考耗时 |
|---|---|---|---|---|---|---|---|
| 1 | demo 业务文档化 | [steps/step1-demo-doc.md](steps/step1-demo-doc.md) | demo/README + FLOW + 第三件套(按形态)| 三件套 5 项文档型验收门全过 | 文档型 | A 必跑;B/C/D 可跳 | 0.5-1 天 |
| 2 | plan 平行分解 | [steps/step2-plan-design.md](steps/step2-plan-design.md) | `plans/00-overview.md` + `01-NN-<维度>.md` | 维度覆盖 demo 所有功能 + 字段单一来源 | 文档型 | A/B/C 必跑;D 探索模式可省 | 1-3 天 |
| 3 | 多轮 review(七维)| [steps/step3-review.md](steps/step3-review.md) | `plans/archive/REVIEW-*.md` + `revision-checklist.md` | 修订后再 review 一轮 P0=0(双轮验证;与回环 ≤3 轮的衔接见 §2 第 6 条) | 文档型 | A/B/C 必跑;D 进工程模式时必跑 | 1-2 周(多轮)|
| 4 | 拆 IMPLEMENTATION | [steps/step4-impl-split.md](steps/step4-impl-split.md) | `IMPLEMENTATION-<模块>.md` | 阶段全景 + 每阶段验收门口令具体 | 文档型 | A/B/C 必跑 | 0.5-1 天 |
| 5 | 分阶段实施 | [steps/step5-execution.md](steps/step5-execution.md) | 实际代码 + NOTES + LOG + TODO + PROGRESS | 每阶段 5/6 项验收门全过 | 代码型(每阶段)| A/B/C 必跑;D 探索模式快速循环 | 数周-数月 |
| 6 | demo 对比调优 | [steps/step6-demo-diff.md](steps/step6-demo-diff.md) | 视觉走查 + 交互回归 + 功能补齐 | dev server 实测主路径全通 | 代码型 | A 必跑;B/C/D 可跳 | 0.5-1 周 |
| 7 | 文档体系生成 | [steps/step7-doc-system.md](steps/step7-doc-system.md) | README + AGENTS + docs/ 矩阵 | 文档型 5 项 + reviewRule 反例溯源 | 文档型 | A 必跑;B/C 追加;D 进工程模式后跑 | 0.5-1 周 |

每个 step 文件统一结构:目标 / 产物 / 验收门类型 / 反问钩子(开头) / Agent 钩子(L0+L1+L2 三层) / 细节 / 本项目示例 / 上下步骤导航。

---

## §2 通用纪律(贯穿全程,9 条)

每个阶段都遵守。措辞采用 **正面指令为主**(Opus 4.7+ 官方推荐:"Tell Claude what to do instead of what not to do")。

### 第 1 条:plan 与 demo 是事实底座

实施期 **只实现 plan 已明示的字段 / 端点 / 函数**。遇 plan 模糊或缺失时:

- **优先在 plan / NOTES 中查找已记录的决策**
- 若查无 → 反问用户(中段反问触发器,见第 6 条)
- 反问代价高时(轻量信息、不影响下游)→ 记入 NOTES 后继续

<example_good>

✓ "plan §3.2 说 `record_status` 字段值是 'active' / 'closed',但实施时遇到 'pending' 是否合理?" — 列具体位置 + 具体问题 + 选项

</example_good>

<example_bad>

✗ "我看了一下 plan,觉得状态机有问题,要不要改一下?" — 模糊问题、无定位、无选项

</example_bad>

### 第 2 条:TaskCreate 跟踪

每阶段创建 `task_granularity_per_stage`(默认 4-8)条子任务;末尾固定一条 `等用户人工敲 commit`(owner=user,unchecked,验收门过完才创建)。

### 第 3 条:Commit 由 hook 拦截(机制层,非 prompt 层)

Commit / amend / tag / rebase / merge / push 等命令由 `.claude/settings.json` PreToolUse hook 拦截。**本工作流不在 prompt 中重复声明这些约束**(详见 §0.3 `<commit_mechanism>`)。

实施期 AI 的职责:
- 完成阶段任务 + `git add` stage
- PROGRESS.md §1 列 staged 文件 + 提示 "本阶段已可 commit"
- 等用户手动 `git commit`

### 第 4 条:失败即停

验收门红 → 不进下一阶段。**5 项验收门全过**(代码到位 / 单测绿 / 集成测/组件测/契约测 / 手工 smoke / grep 防回归);**第 6 项触发条件出现时强制 6/6**(跨模块/跨进程契约对齐;详见 [`workflow-templates/stage-template.md`](workflow-templates/stage-template.md) §0.3)。

### 第 5 条:三轨制 + PROGRESS 四象限职责

|  | 过程态(滚动写) | 结论态(归档) |
|---|---|---|
| **当前态** | **`LOG.md`** — 排错过程 / 临时修法 | **`PROGRESS.md`** — 当前阶段状态 / 产物索引 / 唤醒指针 |
| **历史态** | — | **`NOTES.md`**(决策/修订/补充)+ **`TODO.md`**(V2 backlog)|

边界规则:
- 同一事件最多两处出现,跨处用 `详见 X §Y` 指针引用,内容不复制
- NOTES 区分 `[局部修订]` vs `[路线级修订]`;路线级标注 `IMPLEMENTATION 是否同步重拆`
- PROGRESS 只放 "状态快照 + 唤醒指针";日志放 LOG,决策推导放 NOTES

### 第 6 条:反问钩子 + 三层 review + 回环管理

<asking_hooks>

**开头反问(每阶段开始时)**:每条写成 `yes/no 可答 + 可 grep / 可计数 / 可命名`。

<example_good>

✓ "角色清单 ≥ 3 个具体角色名,列出来:管理员 / 终端用户 / API 调用方" — 可计数 + 可命名
✓ "字段定义 grep 反证:`grep -n 'record_status' plans/*.md` 期望命中 1 处定义 + N 处引用" — 可 grep + 可计数

</example_good>

<example_bad>

✗ "你看一下角色定义有没有问题" — 不可答
✗ "确认字段单一来源" — 无 grep / 无计数

</example_bad>

**中段反问触发器**(实施期遇以下情况立即反问):

- plan 模糊 / 矛盾 **且 NOTES 中也未记录此决策**
- 验收门失败
- L1 agent 报新 P0 **且 P0 与已确认 plan 直接冲突**(P0 与历史 NOTES 一致时按 NOTES 走,不打断)
- NOTES 单条标 `[路线级]`
- demo 差异判定为"无法判定"

> **作用范围**(scope):中段反问仅适用步骤 5 实施期。步骤 3 review 期是 reviewer 角色,不打断主对话发起反问(reviewer 通过 L1 agent 报告 P0)。

</asking_hooks>

<three_tier_review>

**三层 review(每阶段末尾)**:

- **L0 人工 review** — 用户读 X 个槽位 + 给 yes/no 反馈
- **L1 agent 主跑** — prompt 用 [`workflow-templates/review-agent-prompt.md`](workflow-templates/review-agent-prompt.md) 6 槽位 XML 模板;**finding 阶段优先 coverage(报告所有发现,包括 uncertain)**,filtering 由 L0 + L2 完成。多 subagent 设计的 Why 见 §0.4
- **L2 sanity-scan agent**(修订后) — 同 6 槽位填;只跑 6 步扫描清单,不重做七维

</three_tier_review>

<loop_management>

**回环管理(P0=0 双轮验证 + ≤3 轮上限的衔接)**:

- 单条回环上限 `loop_max_rounds`(默认 ≤ 3 轮)
- **回环计数从"修订引起的重 review"开始计**:第 1 轮 review → 修订(不计回环)→ 第 2 轮 review(回环计数 1)→ 修订 → 第 3 轮(计数 2)...
- "**P0=0 双轮验证**" 意味着 **第 2 轮 review 结束时 P0=0**(即回环计数 1 时 P0=0)— 这是默认目标
- 若第 2 轮仍有新回归 P0 → 第 3 轮(计数 2);若第 3 轮仍有 → 计数 3 触发 **L0 拍板:是否延长 1 轮预算 OR 拆分 issue 到 V2**
- **L0 拍板不是 stop,而是 budget extension 决策点**

</loop_management>

### 第 7 条:PROGRESS.md 同步纪律

每阶段末尾(验收门过完) + 每次对话结束前 + 阻塞点出现时 + 中段反问触发时,更新 PROGRESS.md;新会话首读 PROGRESS.md 唤醒上下文。

### 第 8 条:小项目降级规则(避免过度仪式化)

| 降级条件 | 降级方式 | 降级标注位置 |
|---|---|---|
| `plan_loc_lightweight_threshold` 或 `stage_count_lightweight_threshold` 触发 | plan 自审降为 **1 agent + 简版反问 5 条** | PROGRESS.md 顶部元信息:`agent_hook_mode: lightweight` |
| `stage_count_lightweight_threshold` + `stage_loc_lightweight_threshold` 同时触发 | agent 钩子降为 "工作流末尾跑 1 次最终 review"(替代每阶段都跑);反问钩子仍执行 | 同上 |
| **demo 代码 < 500 行 或 主场景路径 ≤ 3 条** | 步骤 1 L1 反向重建可降为 **L0 用户对照 + 1 个简版 sanity-scan**(跳过反向重建 subagent)| PROGRESS.md 顶部元信息:`step1_l1_mode: lightweight (reason: demo<500 loc OR scenes<=3)` |

### 第 9 条:测试验证代码正确性,不验证功能正确性(新增,对应 step6 精神升级)

类型检查 / 测试套件验证代码语法和契约对齐,**不验证业务功能正确性**。任何阶段都不允许 "测试全绿 = 功能完成"。功能完成必须通过:

- **SPA** = dev server 实跑主路径 + 视觉走查
- **后端 API** = curl 实连 + DB 落库验证
- **CLI** = 命令行实际调用 + stdout 验证
- **Notebook** = cell 重跑 + 可视化输出符合预期

验收门第 4 项"手工 smoke" 是这条纪律的固化点。

---

## §3 七步详述(已拆分到 steps/ 子目录)

每步独立一个 markdown 文件,**新会话只需 Read 当前步骤的文件 + 本 SKILL.md(总览/纪律)** 即可:

| 步骤 | 文件 | 关键要点 |
|---|---|---|
| 1 | [steps/step1-demo-doc.md](steps/step1-demo-doc.md) | demo 业务文档化 → 三件套(按形态 SPA/后端 API/CLI/Notebook 4 变体)|
| 2 | [steps/step2-plan-design.md](steps/step2-plan-design.md) | plan 平行分解(4 套裁剪建议)+ 字段单一来源 |
| 3 | [steps/step3-review.md](steps/step3-review.md) | 七维 review + 修订交付协议 + finding/filtering 两阶段 |
| 4 | [steps/step4-impl-split.md](steps/step4-impl-split.md) | 拆 IMPLEMENTATION + 验收门双模板 + 阶段编号约定 |
| 5 | [steps/step5-execution.md](steps/step5-execution.md) | 分阶段实施 + NOTES → plan + IMPLEMENTATION 反向同步回路 |
| 6 | [steps/step6-demo-diff.md](steps/step6-demo-diff.md) | demo 对比调优 + 实测入口(SPA/后端/CLI/Notebook)|
| 7 | [steps/step7-doc-system.md](steps/step7-doc-system.md) | 文档体系生成(README/AGENTS 双轨)+ reviewRule 反例溯源 |

每个 step 文件统一结构:目标 / 产物 / 验收门类型 / 反问钩子(开头) / Agent 钩子(L0 人工 + L1 主跑 + L2 sanity-scan 三层) / 细节 / 本项目示例 / 上下步骤导航。

---

## §4 模板与外部资源(导航)

| 模板 | 用途 | 默认 Read 范围 |
|---|---|---|
| [`workflow-templates/stage-template.md`](workflow-templates/stage-template.md) | 单阶段模板 + 验收门双模板 | 全文 |
| [`workflow-templates/agents-md-skeleton.md`](workflow-templates/agents-md-skeleton.md) | AGENTS.md 五段式 + docs/ 矩阵(含 CLAUDE.md / .cursorrules 等价物说明)| 全文 |
| [`workflow-templates/review-output-template.md`](workflow-templates/review-output-template.md) | finding/filtering 两阶段 + P0/P1/P2 分级 + 修订后扫描 6 步 + revision-checklist | 全文 |
| [`workflow-templates/seven-dim-review.md`](workflow-templates/seven-dim-review.md) | 七维 review 完整提示词 | **默认只读顶部 `<core_summary>` ≤ 100 行;具体 Pass 跑时再 Read 对应章节**|
| [`workflow-templates/progress-template.md`](workflow-templates/progress-template.md) | PROGRESS.md 模板(5 唤醒分支 + 双层修订历史)| 全文 |
| [`workflow-templates/review-agent-prompt.md`](workflow-templates/review-agent-prompt.md) | 独立 agent 6 槽位 XML prompt + 7 类视角 few-shot | 启动 agent 前对应视角段 |

---

## §5 退出条件 / 多 AI 接手 / V2 增量 / 长期续做(晚期触发,按需展开)

> 这些规则只在**工作流晚期、跨 AI 接手、或长期搁置后续做**时才用,日常实施不需要常驻。触发时展开 [`references/handover-and-longrun.md`](references/handover-and-longrun.md),内含:
>
> - **退出条件**:步骤 7 完成后的后续分支(V2 增量 → 入口 C / 重大架构 → 入口 A / 维护增量 → 入口 B)
> - **多 AI 接手协议**:接手 AI 走"提示流程,用户拍板",不自动启动 sanity-scan
> - **长期续做规则**:`> stale_warmup_milestone_days` / `> stale_warmup_overview_days` 的重读层级
