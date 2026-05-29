# 步骤 5:分阶段实施

> **配套**:[../SKILL.md](../SKILL.md) 总览 + 通用纪律 · 上一步 → [step4-impl-split.md](step4-impl-split.md) · 下一步 → [step6-demo-diff.md](step6-demo-diff.md)
>
> **入口适配**:A / B / C 必跑;D(PoC)探索模式快速循环
>
> **重点**:IMPLEMENTATION 是滚动文档,不是一次拆完不动 — 实施期发现 plan / IMPLEMENTATION 错误需反向同步

---

**目标**:按阶段顺序写代码 + 5/6 项验收门 + 三层 review + 三轨制跟踪。

**产物**:
- 实际代码
- `plans/IMPLEMENTATION-NOTES.md`:plan 偏差对账 —— 遇 plan 与代码冲突以本文件为准
- `plans/LOG.md`:踩坑日志(排错过程 / 临时修法)
- `plans/TODO.md`:V2 backlog(P1/P2 优先级)
- `PROGRESS.md`:每阶段末尾同步

**验收门类型**:代码型(每阶段 5/6 项)

**每阶段执行流程**:
1. **开头**:反问钩子(6 条)+ TaskCreate 拆 `task_granularity_per_stage` 子任务(默认 4-8;末尾固定 "等用户敲 commit" task,owner=user)
2. **中段**:写代码 + 跑测试 + grep 防回归;遇任何不确定 → 中段反问触发器(详见 SKILL.md §2 第 6 条 scope)
3. **末尾**:5 项验收门逐项过 + **L0 人工 ack** + 启动 **L1 review agent**(coverage 优先,带 confidence);修订后跑 **L2 sanity-scan**
4. **更新 PROGRESS.md**(staged 队列 + 可 commit 提示 + NOTES 未回写计数 + 接手必读字段 + 回环计数)
5. **commit**:`commit_per_stage` 个 / 阶段(默认 1-3),用户人工触发(拦截机制详见 SKILL.md §0.3 `<commit_mechanism>`)

**反问钩子(每阶段开头)— 按必答类别 coverage 组织,每类至少 1 条**:

<asking_examples>

| 类别 | 至少 1 条 yes/no 钩子 |
|---|---|
| **上阶段验收门证据** | 上一阶段 5/5 或 6/6 全过?列每项实际证据(grep 命中数 / pytest 退出码 / curl 响应码) |
| **本阶段 plan 清晰度** | 本阶段 plan 是否清晰?**模糊 → 先查 NOTES,再反问**(scope:仅本步骤实施期)|
| **远程依赖准备** | 远程依赖 / 密钥 / 第三方账号是否提前准备?|
| **TaskCreate 颗粒** | 本阶段 TaskCreate 4-8 子任务?末尾 `等用户敲 commit` task(owner=user)已创建?|
| **NOTES 未回写计数** | 当前 NOTES 未回写 < `notes_writeback_trigger`?如已达阈值,先 batch 回写再继续 |

**Good vs Bad**:

✓ "上阶段 S2 5/5 验收门:`pytest exit=0 / curl :8000/api/v1/X → 200 / grep 'old_name' = 0`,逐项列证据?" — 可命令 + 可计数
✓ "NOTES 未回写计数 = 7 < 10,本阶段先继续,不触发 batch 回写?" — 可计数
✗ "上阶段差不多过了" — 不可验证
✗ "依赖都准备好了吧" — 不可答

</asking_examples>

**Agent 钩子(三层,按阶段类型选 L1)**:

> **通用 agent 规则**:详见 [`../SKILL.md`](../SKILL.md) §0.4 + §2 第 6 条。本步骤特有 — Pass 3 finding 必须带 `<implementer_reverse_code>` 字段;数据模型 / API 契约阶段启动 2 个独立 agent 交叉验证(Why:finding 重叠度 < 40%,显著提升 recall;详见 SKILL.md §0.4)。

- **L0 人工**:用户审阅 5/6 项验收门实际证据 + 修订点
- **L1(按阶段类型选)**:
  - 业务逻辑阶段 → Plan agent 七维 Pass 3+5(实施者反向 + 覆盖范围)
  - 重构 / 整合阶段 → Plan agent 七维 Pass 6+7(跨层对照 + sanity scan)
  - **数据模型 / API 契约阶段 → 2 个独立 agent**(1 Plan 实施者反向 + 1 Explore 覆盖范围,交叉验证)
    - **Why 2 agents**(给 4.7+ 的解释):数据模型/契约错误代价高,2 个独立视角的 finding 重叠度 < 40%,显著提升 recall。这里多 agent 是有意设计;详见 SKILL.md §0.4
- **L2**:修订后 sanity-scan
- 所有 agent 用 [`../workflow-templates/review-agent-prompt.md`](../workflow-templates/review-agent-prompt.md) XML 6 槽位填

---

## NOTES → plan + IMPLEMENTATION 反向同步回路

实施期发现 plan / IMPLEMENTATION 与代码不一致时:

- **[局部修订]**(单字段 / 单签名漂移):
  - 仅 NOTES 记录,标 `Fixed in <plan §章节>`
  - plan + IMPLEMENTATION 可暂不改
- **[路线级修订]**(技术栈 / 架构 / 数据模型反向):
  - plan 文件原地改(主 plan)
  - IMPLEMENTATION-<模块>.md 同步重拆(影响阶段重置验收门)
  - 回到步骤 3 重跑七维 review;review 焦点 = 修订后的主 plan + IMPLEMENTATION + NOTES 三处一致
  - 优先走局部 review 轻量分支(只跑受影响 pass);不强制 7 pass 全跑
  - **回环退出**:同一路线级修订重 review ≤ `loop_max_rounds` 轮,超出触发 L0 拍板(选项 A/B/C)
- **触发回写 batch**:
  - NOTES 累计 ≥ `notes_writeback_trigger`(默认 10 条)或 出现路线级修订
  - → 停下来跑 NOTES → plan + IMPLEMENTATION 批量回写 + 重启七维 review
- PROGRESS.md §1 含 `NOTES 未回写计数 / 上次回写日期 / 是否触发 IMPLEMENTATION 改`

**NOTES 体例**:按阶段编号(`S0-D1` / `F3-D1`)记决策;**[局部] vs [路线级]** 必明示;路线级标 "IMPLEMENTATION 是否同步重拆"

**LOG 体例**:按问题类型 / 日期,排错细节,与 NOTES 不重复

**本项目示例**:`archive/plans/IMPLEMENTATION-NOTES.md` + `LOG.md` + `TODO.md`
