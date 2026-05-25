# PROGRESS.md 模板(跨会话唤醒锚点)

> 本模板供 SKILL.md 步骤 5 实施期 + 跨会话续做 + 多 AI 接手引用。每个新项目复制此模板到仓库根 `PROGRESS.md`,然后按实际填写。
>
> **核心定位**:新会话首读文件。Read PROGRESS.md 后,按 §5 动态唤醒指针(按当前阶段分支)继续 Read 上下文。
>
> **更新时机**:每阶段末尾 + 每对话结束前 + 阻塞出现时 + 中段反问触发时。

---

## 顶部元信息(每次更新同步)

```yaml
project: <项目名>
current_date: YYYY-MM-DD
last_updated: YYYY-MM-DD HH:MM
current_stage: <步骤 N — 阶段编号 — 阶段名>
entry_mode: A 新建有 demo  /  B 维护性增量  /  C V2 增量  /  D PoC 探索
agent_hook_mode: full (每阶段都跑 L1/L2)  /  lightweight (工作流末尾跑 1 次最终 review)
runtime_mode: 工程模式  /  探索模式(仅 PoC 入口 D)

# Claude Opus 4.7 配套配置(WORKFLOW 推荐)
claude_opus_4_7_config:
  effort: xhigh  # 或 max(超长 horizon)
  thinking: adaptive
  max_tokens: 64000

# 数字阈值覆盖(可选,默认值见 SKILL.md "数字阈值单一来源")
thresholds:
  # 取消注释来覆盖默认值
  # task_granularity_per_stage: 4-8
  # loop_max_rounds: 3
  # notes_writeback_trigger: 10
  # stale_warmup_milestone_days: 14
  # stale_warmup_overview_days: 30
```

---

## §1 当前状态(每次更新)

### 正在做
- **步骤 N** — 阶段编号 — 阶段名 — 第 K 个子任务
- 本阶段开始时间:YYYY-MM-DD
- 本阶段 TaskCreate ID 列表:#NN / #NN+1 / ...

### 阻塞点(无 / 具体描述)
- 阻塞 1:<描述>
  - 影响:<哪些下游被影响>
  - 等谁拍板:<用户 / 上游模块 / 第三方>
- 无:✓

### staged 但未 commit 文件清单

> AI 完成阶段任务 + stage 后,在本段列文件清单 + 提示"本阶段已可 commit"。Commit message 由用户撰写。
> 拦截机制:`.claude/settings.json` PreToolUse hook 拦截 AI 主动调用 git commit / amend / tag / rebase / merge / push(用户主动调用不拦截)。详见 SKILL.md §0.3 `<commit_mechanism>`。

- `<file 1>`:<改动一句话>
- `<file 2>`:...

**提示**:本阶段已 staged,可 commit;message 待用户撰写(prefix 参考 `stage-template.md` §1.5)。

### NOTES → plan + IMPLEMENTATION 反向同步追踪
- NOTES 未回写计数:N(超过 `notes_writeback_trigger` 触发 batch 回写)
- 上次回写日期:YYYY-MM-DD
- 本阶段是否触发 IMPLEMENTATION 改:否 / 是(标 [路线级修订] 时强制)
- 本阶段是否有 [路线级修订]:否 / 是 + 详见 NOTES §X

### 接手必读(多 AI 协作场景)

> 后续 AI 接手本任务时,先读此段了解前手状态

- 前手最后决策:<最近一次拍板 + 理由>
- 待用户拍板事项(若有):列入 §4
- 风格偏好:<commit message 中文 / 反问钩子粒度 / 测试覆盖优先级 等>
- 前手最后 3 次 commit:`git log -3 --oneline` 结果

### 回环计数(任一 ≤ `loop_max_rounds` 轮;超出 → L0 拍板,选项 A/B/C)

| 回环 | 当前轮次 | 状态 |
|---|---|---|
| <plan 部分 X> 修订 → review | 2 / 3 | 进行中 |
| <IMPLEMENTATION 部分 Y> 修订 → review | 1 / 3 | 进行中 |
| <反问 Z> → 修订 → 反问 | 0 / 3 | 未触发 |

**L0 拍板选项**(超出 ≤ 3 轮时):
- A: 延长 1 轮预算(`loop_max_rounds` + 1)
- B: 拆剩余 P0 到 V2
- C: 重新评估 plan(回环未收敛 = 设计问题)

详见 `review-output-template.md` §3.5。

### 下一步
- 本阶段完成后:<下一阶段编号 + 一句话>
- 预期阻塞 / 风险:<列出 1-3 条>

---

## §2 已完成阶段清单

| 状态 | 阶段号 | 名称 | 完成日期 | 验收门类型 | 产物路径 | review 记录 |
|---|---|---|---|---|---|---|
| `[x]` | 0 | Plan 自审 | YYYY-MM-DD | 文档型 | `plans/archive/REVIEW-self-audit-YYYY-MM-DD.md` | sanity-scan 通过 |
| `[x]` | 1 | demo 业务文档化 | YYYY-MM-DD | 文档型 | `demo/README.md` + `demo/FLOW.md` + `demo/CODE_INDEX.md` | L0+L1+L2 全通过 |
| `[ ]` | 2 | plan 平行分解 | — | 文档型 | — | — |
| `[ ]` | ... | ... | ... | ... | ... | ... |

---

## §3 产物索引表

| 产物 | 路径 | 状态 | 最后改动日期 |
|---|---|---|---|
| SKILL.md | `SKILL.md` | final | YYYY-MM-DD |
| 七维 review 模板 | `workflow-templates/seven-dim-review.md` | final | YYYY-MM-DD |
| stage-template | `workflow-templates/stage-template.md` | final | YYYY-MM-DD |
| PROGRESS 当前 | `PROGRESS.md` | draft(滚动)| — |
| <业务产物 1> | `<path>` | draft / reviewed / final | YYYY-MM-DD |

**状态约定**:
- `draft` — 初稿,未经 review
- `reviewed` — 已经 L1 agent review,但未 L0 人工拍板
- `final` — L0 人工 + L1 + L2 全通过,可对外

---

## §4 阻塞 / 待用户拍板

中段反问触发时实时写入。所有待人工拍板项(包括"demo 偷懒不需补齐"类 trade-off)都汇集在本段,按 [类型] 标签区分:

### 待用户拍板

- **<问题 1>**(由步骤 N 中段反问触发,YYYY-MM-DD)[**类型**:plan 模糊 / 验收失败 / demo-保留态 / 长期 trade-off / 其他]
  - 背景:...
  - 选项 A:...(代价 / 收益)
  - 选项 B:...
  - **等用户:**

**类型标签清单**:
- `[plan-模糊]` — plan/IMPLEMENTATION 矛盾或缺漏触发
- `[验收失败]` — 验收门红了等用户决定
- `[demo-保留态]` — demo 偷懒处,工程版本不需补齐
- `[路线级修订]` — NOTES 标 [路线级] 触发
- `[长期 trade-off]` — 等监控反馈 / V2 决策
- `[loop-上限]` — 回环超 3 轮,等 L0 选 A/B/C
- `[其他]` — 不属于上述

---

## §5 动态唤醒指针(新会话第一动作)

> 新会话首读 PROGRESS.md → 根据"当前阶段"选下面对应分支 → **按 "目标 + 最小读取集 + 按需扩展" 自适应读取** → 再继续工作。
>
> "最小读取集"够则停;复杂场景才走"按需扩展"。不要按固定步骤序列死板 Read,让 adaptive thinking 决定每次该 Read 多少。

<wakeup_branch_1_plan_phase>

### 分支 1:当前在步骤 1-2(plan 设计期)

**目标**:回到"按 demo 设计 plan 维度"的工作状态,能继续拆 plan 或修订 plan。

**最小读取集**(够则停):
- `SKILL.md`(总览/纪律)
- 当前步骤文件:`steps/step1-demo-doc.md` 或 `steps/step2-plan-design.md`
- 当前 plan 文件(`plans/0X-<维度>.md`)+ TaskList

**按需扩展**(以下场景才读):
- 不熟 demo 业务 → 读 `demo/README.md` + `demo/FLOW.md` + `demo/CODE_INDEX.md`(三件套)
- plan 维度划分困惑 → 读 `plans/00-overview.md`
- 卡在反问钩子 → 读 当前 step 文件的 `<asking_examples>` 段重新校准

</wakeup_branch_1_plan_phase>

<wakeup_branch_2_review_phase>

### 分支 2:当前在步骤 3(review 期)

**目标**:回到"基于 plan 跑七维 review 或处理 review finding"的工作状态。

**最小读取集**:
- `SKILL.md`
- `steps/step3-review.md`
- 最近一份 `plans/archive/REVIEW-*.md` + 对应 `revision-checklist.md`
- §1 回环计数(本文件)— 接近 `loop_max_rounds` 时优先 L0 拍板

**按需扩展**:
- 要跑新一轮 review → 读 `workflow-templates/seven-dim-review.md` `<core_summary>` + 当前 plan 全部文件
- 跑某个具体 Pass → 读对应 `workflow-templates/seven-dim/pass-N-*.md`
- 修订后 sanity-scan → 读 `workflow-templates/seven-dim/revision-scan-checklist.md`

</wakeup_branch_2_review_phase>

<wakeup_branch_3_impl_phase>

### 分支 3:当前在步骤 4-6(实施期)

**目标**:回到"按阶段写代码 + 跑验收门"的工作状态,能继续当前阶段或开下一阶段。

**最小读取集**:
- `SKILL.md`
- 当前步骤文件(`steps/step4-impl-split.md` / `step5-execution.md` / `step6-demo-diff.md`)
- `plans/IMPLEMENTATION-<模块>.md` 当前阶段章节
- TaskList

**按需扩展**:
- 阶段产物的源 plan 不清晰 → 读 `plans/0X-<维度>.md`
- 与已有 NOTES 决策有冲突 → 读 `plans/IMPLEMENTATION-NOTES.md`(最近 N 条)
- 改代码前要看上下文 → Read 当前阶段产物所在文件 / 目录
- 验收门失败 / L1 报新 P0 → 触发中段反问(WORKFLOW §2 第 6 条 scope)

</wakeup_branch_3_impl_phase>

<wakeup_branch_4_doc_phase>

### 分支 4:当前在步骤 7(文档生成期)

**目标**:回到"产出 AGENTS.md / docs/ 矩阵 / reviewRule"的工作状态。

**最小读取集**:
- `SKILL.md`
- `steps/step7-doc-system.md`
- `workflow-templates/agents-md-skeleton.md`

**按需扩展**:
- 生成 reviewRule → 读 `archive/plans/LOG.md` + `IMPLEMENTATION-NOTES.md` + `archive/plans/archive/REVIEW-*.md`(反例溯源)
- 填 AGENTS.md §1 索引表 → 读 各模块代码主入口
- 校验 5 个典型查询能否命中 → 启动 L1 文档可索引性 agent(详见 step7 Agent 钩子)

</wakeup_branch_4_doc_phase>

<wakeup_branch_5_handover>

### 分支 5:接手分支(多 AI 协作)

> 前一个 AI 中断 / 交班,后续 AI 接手时走此分支(不重跑 plan 自审)
>
> 接手 AI 走 **"提示流程,用户拍板"**;AI 不自动启动 sanity-scan agent

1. Read 本 PROGRESS.md 全文(尤其 §1 接手必读字段)
2. Read 前手最后 3 次 commit 改动(`git log -3 --oneline` + `git show <hash>`)
3. 提示用户(不自动启动 agent):
   > "已读完 PROGRESS,前手最后在 **<阶段 N>** 的 **<子任务>**;是否需要我跑 1 个 agent 增量 sanity-scan 扫前手最后 N 次修订漂移?(推荐 / 跳过 / 自定义)"
4. 由用户拍板:
   - **推荐** → 启动 sanity-scan agent(prompt 用 `review-agent-prompt.md` XML 6 槽位,角色定位=接手 sanity-scan,必读=前手最后 N 次修订)
   - **跳过** → 直接按当前阶段在分支 1-4 中选对应继续
   - **自定义** → 按用户指示
5. 根据当前阶段在分支 1-4 中选对应继续

</wakeup_branch_5_handover>

### 长期续做特殊规则

- `> stale_warmup_milestone_days`:Read §6 里程碑摘要层(每阶段 1 条 + 路线级修订 1 条)+ 近期 10 条
- `> stale_warmup_overview_days`:额外重读 `plans/00-overview.md`(plan 设计意图)

---

## §6 修订历史(双层)

### 6.1 近期摘要(最近 10 条,日期倒序)

```
YYYY-MM-DD <一句话改动>
YYYY-MM-DD <一句话改动>
...
```

### 6.2 里程碑摘要(每阶段 1 条 + 路线级修订 1 条;> stale_warmup_milestone_days 必读)

```
[阶段 0 完成] YYYY-MM-DD — Plan 自审 P0=0 + 修订 X 处
[阶段 1 完成] YYYY-MM-DD — demo 三件套写完 + L0/L1/L2 全通过
[路线级修订 R1] YYYY-MM-DD — 技术栈 X → Y(详见 NOTES §X1)
[阶段 2 完成] YYYY-MM-DD — plan 平行分解 7 份完成 + 七维 review P0=0
...
```

何时写入里程碑层:
- 阶段验收门全过完(§2 打 `[x]`)
- 出现路线级修订(NOTES [路线级] 标记)
- 重大决策拍板(用户对 §4 待拍板事项给出明确选择)

---

## §7 元层注意事项

- PROGRESS.md 不放"日志"性质内容(那是 LOG.md 的职责)
- PROGRESS.md 不放"决策详细推导"(那是 NOTES.md 的职责)
- PROGRESS.md 只是"状态快照 + 唤醒指针":让新会话能在 ~5 分钟内回到工作状态
- 若 PROGRESS.md 体量超过 300 行:大概率混了 LOG / NOTES 内容,应拆出去
