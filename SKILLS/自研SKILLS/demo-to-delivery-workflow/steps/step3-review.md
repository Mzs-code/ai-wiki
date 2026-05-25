# 步骤 3:Plan 多轮 Review(七维方法论)

> **配套**:[../SKILL.md](../SKILL.md) 总览 + 通用纪律 · 上一步 → [step2-plan-design.md](step2-plan-design.md) · 下一步 → [step4-impl-split.md](step4-impl-split.md)
>
> **入口适配**:A / B / C 必跑;D(PoC)进工程模式时必跑

---

**目标**:用七维方法论压平 plan 矛盾 / 漏洞,P0=0(修订后再 review 一轮 P0=0,双轮验证)才进步骤 4;回环 ≤ `loop_max_rounds` 轮,超出触发 L0 拍板(选项 A/B/C,详见 [`../workflow-templates/review-output-template.md`](../workflow-templates/review-output-template.md) §3.5)。

**产物**:
- `plans/archive/REVIEW-<reviewer 角色>-<日期>.md` — review 报告
- 每轮修订后提交 `plans/archive/REVIEW-<reviewer 角色>-<日期>-revision-checklist.md`(Step 1-6 逐项做了 / 跳过原因);未交付即视为修订未完成

**验收门类型**:文档型 5 项

**七维 pass**(核心摘要在 [`../workflow-templates/seven-dim-review.md`](../workflow-templates/seven-dim-review.md) `<core_summary>`,默认只读摘要;具体 Pass 触发时读对应 `<pass_N_*>` 锚点):

1. 链路追踪(声明 → 实现 → 调用 → 异常路径)
2. Self-claim 验证(grep 反证)
3. 实施者反向(真敲 30-80 行模拟代码)
4. 框架运行时语义(SQLAlchemy / FastAPI / asyncio / React Query / Pydantic / Zustand 等)
5. 覆盖范围反向(列出每个机制不覆盖的场景)
6. 跨层对照(UX ↔ API ↔ 数据模型 ↔ service)
7. 大改后 sanity scan(章节漂移 / import 漂移 / 旧命名残留)

**review 两阶段流程**:

- **Phase A — Finding**(L1 agent):coverage 优先,报告所有发现(含 uncertain / low-severity),每条带 confidence + severity 估计;不自我过滤
- **Phase B — Filtering**(L0 + L2):基于 Phase A 输出做 P0/P1/P2 分级 + 修法可执行性评估 + trade-off 标记

详见 [`../workflow-templates/review-output-template.md`](../workflow-templates/review-output-template.md) §1。

**反问钩子(开头)— 按必答类别 coverage 组织,每类至少 1 条**:

<asking_examples>

| 类别 | 至少 1 条 yes/no 钩子 |
|---|---|
| **上轮 Fixed 验证** | 上一轮 P0/P1 全部 Fixed?Fixed ≠ 在 NOTES 标 "Fixed in",需 plan 文件原地改 + grep 反证 |
| **七 pass 覆盖** | 七 pass 都跑了?跳哪个 / 为什么?(小项目可降级跑 Pass 1+2+3+7,但在 review 报告显式声明 `<pass_skipped reason="...">`)|
| **修订后 sanity-scan 复扫** | 修订后经过独立 sanity-scan agent 复扫确认 0 回归?(实战经验:每轮修订都有 1-2 项是修订引入的回归) |
| **回环计数** | 本部分 review 第几轮?接近 `loop_max_rounds` 时准备 L0 拍板选项 A/B/C |
| **Pass 3 真敲代码** | Pass 3 finding 都带 `<implementer_reverse_code>` 字段?未带 → L0 判 agent 失格 |

**Good vs Bad**:

✓ "上轮 P0/P1 全部 Fixed?grep 'Fixed in §' 命中数 = 上轮 P0 总数?" — 可 grep + 可计数
✓ "本轮 review 第 2 轮?(回环计数 = 1,P0=0 双轮验证目标)" — 可计数
✗ "上轮的问题都改了吧?" — 不可验证
✗ "review 跑得差不多了" — 无具体指标

</asking_examples>

**Agent 钩子(三层 + 局部分支)**:

> **通用 agent 规则**:详见 [`../SKILL.md`](../SKILL.md) §0.4 + §2 第 6 条。本步骤特有 — Pass 3 finding 必须带 `<implementer_reverse_code>` 字段(机械校验,详见 [`../workflow-templates/review-output-template.md`](../workflow-templates/review-output-template.md) `<finding_phase_format>`)。

- **L0 人工**:用户对照 REVIEW 报告**逐 P0 拍板**(必修 / trade-off / 不修)
- **L1 七维 review agent**:首次启动 ≥ 1 个;高风险节点(数据模型 / API 契约)启动 2 个交叉验证(why:经验值 finding 重叠度 < 40%);每个 agent 的 prompt 用 [`../workflow-templates/review-agent-prompt.md`](../workflow-templates/review-agent-prompt.md) XML 6 槽位填:
  - `<role>`:七维 review(或实施者反向 / 覆盖范围反向 等更细)
  - `<must_read>`:plan 全部文件 + seven-dim-review.md `<core_summary>` + 具体触发的 `<pass_N_*>` 锚点
  - `<output_format>`:`<finding_phase_format>`(coverage 优先,带 confidence/severity)
  - `<constraints>`:任一 pass 不静默跳过;self-claim 必须 grep 反证
  - `<failure_examples>`:首轮 `<no_prior_examples/>`;后续轮次抽上一轮典型 P0
  - `<user_context>`:...
- **L2 sanity-scan agent**(修订后):只跑 6 步扫描清单,不重做七维;同 XML 6 槽位填
- **局部 review 轻量分支**(路线级修订时):只跑受影响 pass(列出受影响维度 → 受影响 pass;详见 [`../workflow-templates/review-output-template.md`](../workflow-templates/review-output-template.md) §6)

**修订交付协议**:

- **P0=0 语义**:修订后再 review 一轮 P0=0(双轮验证),不是单次 review 标 Fixed 就算
- 修订写在 plan 文件原地(不另起 final plan);REVIEW.md 用 "Fixed in <plan §章节>" 形式追溯
- 每轮 review 修订完显式提交 `revision-checklist.md`
- **回环退出**:同一 plan 部分 review 重跑 ≤ `loop_max_rounds` 轮,超出触发 L0 拍板(选项 A/B/C)

**放行规则**:修订后 review 一轮 P0=0 才进步骤 4

**本项目示例**:`archive/plans/archive/backend -REVIEW.md`(多轮 review 沉淀)
