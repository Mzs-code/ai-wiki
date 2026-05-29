# review-workflow-template.md — Workflow 化的 L1/L2 review fan-out(模型 ≥ Opus 4.8 启用)

> **核心定位**:把 SKILL.md 步骤 3 / 步骤 5 的「启动 L1/L2 review agent」从**主对话手动 spawn + prompt 劝说**,升级为 **Workflow 工具的确定性编排**。
>
> **与 `review-agent-prompt.md` 的关系**:本模板**不替代**它。两条路**并存**,由模型版本门控(见 §0)。`review-agent-prompt.md` 的 6 槽位 XML 描述、§1/§1.5「为什么用多 subagent」「must_not_read 元层作用面」等**全部保留不变** —— 在低于 Opus 4.8 的模型上仍是主路径。本模板是模型够新时的**等价升级路径**,prompt 内容直接沿用那 6 槽位。
>
> **数字阈值**:见 [`../SKILL.md`](../SKILL.md) "数字阈值单一来源" 块,本文件不重复声明。

---

## §0 要不要用本模板?两道前置门

### §0.1 第一道门:这次 review 该用 subagent 还是 workflow?

<when_workflow_vs_subagent>

**默认 = subagent + 对话**(走 [`review-agent-prompt.md`](review-agent-prompt.md) 原钩子)。本模板是**例外升级件**,只在命中下面任一窗口时才用 —— 否则一个"2-3 agent、人全程盯着"的普通 review 用 workflow 是**杀鸡用牛刀**:

| 升级窗口(命中任一才上 workflow) | 说明 |
|---|---|
| **W1 可复现硬要求** | 跨多项目 / 多 review 门,要求 prompt 拼装 + finding 格式 + Pass3 校验**每次字节级一致**,当质量棘轮 |
| **W2 宽 fan-out** | 大型多模块 plan,单门需 **> 3 个独立深度 reviewer 并行**(类比"审计 10 个微服务:文件不多但每个要深挖");此时**主动放开 §1 的 2-3 上限** |
| **W3 硬 schema 契约** | finding 必须机器校验、Pass3 缺真敲代码必须自动拦,不接受"尽力而为" |

**反指征(命中任一 → 留在 subagent,别上 workflow)**:

- 单门 **≤ 2-3 个 agent** 且主对话一条消息就能并发协调 → 没超出协调范围
- review 需要"**做到一半让用户看方向对不对**" → workflow 运行中**不能插用户反馈**
- **小 plan**(< 20 文件 / 单模块,一个 agent 一轮扫完)→ 规模没上来

**文件 / 实体数参考线**(决策流,非死规则):< 20 → subagent;20-100 → 看情况;> 100 → 优先 workflow。**但复杂度优先于数量**:深度审计型(文件少、每个要深挖)即使数量不到也可上 workflow。

**一句话**:规模没上来(≤ 2-3 agent)、又是人全程盯着拍板的普通 review,就用 subagent;只有要 **W1 可复现 / W2 宽 fan-out / W3 硬 schema** 时才升级本模板。

</when_workflow_vs_subagent>

### §0.2 第二道门:模型版本门控

<model_gate>

**门控决策(命中第一道门、已决定上 workflow 后,再按模型版本判一次)**:

| 当前运行模型 | review agent 启动方式 |
|---|---|
| **≥ Opus 4.8** | **用本模板**(Workflow 工具编排);把 6 槽位 prompt 作为 `agent()` 的输入,finding 格式用 schema 强制 |
| **< Opus 4.8(含 4.7)** | **走原有 subagent 钩子**:SKILL.md §0.4 + [`review-agent-prompt.md`](review-agent-prompt.md) 主对话手动 spawn(保留不变)|

**为什么门控、为什么两条路并存**:

- `review-agent-prompt.md` §1 / §1.5 那一大段"对 4.7 的劝说"(必须真 spawn、别用主对话假装 review、`<must_not_read>` 切断 echo chamber),存在的唯一理由是**早期模型可能不 spawn 或做"伪 subagent" reasoning**。
- Workflow 工具的 `agent()` 是**确定性进程级 spawn**:agent 结构上拿不到主对话 transcript,echo chamber **物理隔绝**;不存在"降级为主对话 reasoning"的选项。所以在 ≥ 4.8 上,那段劝说对本路径而言是多余的 —— 但**不删它**,因为它仍是低版本路径的主依据。
- 因此:**模型够新 → 让结构替你保证(本模板);模型不够新 → 让 prompt 劝说替你保证(原钩子)**。

</model_gate>

### §0.3 opt-in 合法性

<opt_in>

**opt-in 合法性**:Workflow 工具要求"显式 opt-in"才能调用。其触发规则明确包含一条 —— **"用户调用的 skill / slash command 的指令要求调用 Workflow"即算合法 opt-in**。本 skill 在 review 门指示 Claude 用本模板,正属此列,**不算越权自启工作流**。调用前无需再单独征求"要不要开工作流",但**计费提示仍应在主对话说明**(一次 review run 约 1-2 个 agent)。

</opt_in>

---

## §1 agent 数量纪律(硬约束 —— 一次只 2-3 个,不是 20-30 个)

<agent_count_discipline>

本模板的 fan-out **刻意保持小规模**,与 SKILL.md §0.4 / step3 / step5 现有设计一致:

| 场景 | finder agent 数 | 依据 |
|---|---|---|
| 普通节点(单一视角七维 review) | **1 个** | step3「首次启动 ≥ 1 个」 |
| 高风险节点(数据模型 / API 契约) | **2 个并行交叉** | step5「2 个独立 agent;finding 重叠度 < 40% → recall」 |
| 修订后复扫 | **单独一次 `mode=sanity`,1 个** | step3 L2 sanity-scan |

**脚本内置上限 = 2**:即使 `args.perspectives` 传入更多视角,普通节点只跑 1 个、高风险只跑 2 个,**多出的视角被截断并 `log()` 提示**(不静默丢弃),需另起一轮 review。**任何单次 Workflow run 的 agent 数 ≤ 2。** 严禁把七维的 7 个 pass 展开成 7 个 agent,或一次铺 20-30 个 agent。

</agent_count_discipline>

---

## §2 边界:本脚本只做"单轮 Phase A finding",回环与 L0 留在主对话

<boundary>

Workflow 在**后台自主跑完才返回,中途不会停下来问用户 yes/no**。而本 skill 的灵魂是"每个验收门 L0 人工拍板"。因此**严格划界**:

- **本脚本接管的**:Phase A — Finding(L1 多视角并行产 finding,coverage 优先 + schema 强制格式),以及修订后的 L2 sanity-scan。
- **仍留在主对话 + 用户的**:
  - **Phase B — Filtering**(P0/P1/P2 分级 + 修法可执行性 + trade-off 标记)
  - **L0 拍板**(逐 P0:必修 / trade-off / 不修)
  - **跨轮回环**(L0 拍板 → 人工修订 plan → 再调一次本脚本):**一次 Workflow run = 一轮 finding**;回环计数 / P0=0 双轮验证 / ≤ `loop_max_rounds` 退出,都由主对话按 SKILL.md step3 驱动,因为**修订必须人工**。

**数据流**:主对话调本脚本 → 拿回结构化 `findings`(未过滤的 coverage 合集)→ 主对话带用户做 Phase B + L0 → 人工修订 → (需要时)再调本脚本下一轮。

</boundary>

---

## §3 调用契约(`args`)

主对话调用 `Workflow` 工具时,通过 `args` 传入(脚本读 `args.*`):

| 字段 | 类型 | 说明 |
|---|---|---|
| `mode` | `'finding'`(默认)/ `'sanity'` | finding = 跑 1-2 个 review agent;sanity = 跑 1 个修订后复扫 agent |
| `round` | number | 本轮回环计数(从 1 起),填入 prompt 的 `<user_context>` |
| `isHighRisk` | boolean | 高风险节点(数据模型 / API 契约)→ 允许 2 个 finder 交叉;否则 1 个 |
| `perspectives` | `[{role, focus}]` | 视角列表;role 取自 review-agent-prompt §3 八类视角名;focus 是一句话任务目标。脚本按 §1 上限截断 |
| `mustRead` | string[] | 每个 agent 的 `<must_read>` 文件路径(**当前项目里有效的路径**:plan 文件 + 方法论文件等)|
| `mustNotRead` | string[] | `<must_not_read>` 条目;缺省给默认(主对话历史 / 上一轮 reviewer 修订建议)|
| `methodology` | string | 方法论指针,缺省 `seven-dim-review.md <core_summary>` |
| `failureExamples` | string / null | 上一轮典型 P0 摘抄;首轮传 null(脚本填 `<no_prior_examples/>`)|
| `userContext` | object | `{projectType, stage, tradeoffs, stylePref, priorAsks, revisionSummary}` |
| `sanityScope` | string[] | 仅 `mode='sanity'`:本轮修订涉及的 plan 段落 + revision-checklist 等 |

> **路径注意**:`mustRead` / `methodology` 由主对话填**当前项目上下文里可读的路径**。plan 文件在用户项目里;方法论文件(`seven-dim-review.md`)在本 skill 安装目录下 —— 主对话需填其可达路径(通常是绝对路径)。本模板不硬编码。

---

## §4 finding 输出 schema(对应 `review-agent-prompt.md` §2.5)

schema 在**工具调用层强制校验**,agent 无法自我过滤或漏字段 —— 这把 §2.5 的"字段约定"从文档约定升级为**契约**。字段与 `<finding_phase_format_minimal>` 一一对应:`id / confidence / severity_estimate / location / original_quote / observation / impact / category / pass_trace`(+ Pass 3 的 `implementer_reverse_code`)。

**`implementer_reverse_code` 机械校验自动化**:JSON Schema 无法表达"Pass 3 才必填",故脚本在返回前**自动扫描**:凡 `pass_trace` 命中 Pass 3 / 实施者反向但缺 `implementer_reverse_code` 的 finding,收进 `passThreeViolations` 返回 —— 主对话据此判该视角 agent 失格、重启(对应 §2.5「L0 应判失格、重启 agent」,现在变成机器先标出来)。

---

## §5 脚本(可直接作为 `Workflow` 工具的 `script` 传入;或存盘后用 `scriptPath` 复用)

```js
export const meta = {
  name: 'demo-to-delivery-review',
  description: 'demo-to-delivery-workflow 的 L1/L2 review fan-out:1-2 个独立 agent 并行产 finding(coverage 优先,schema 强制格式);回环/filtering/L0 拍板留在主对话',
  phases: [
    { title: 'Finding', detail: '1-2 个独立 review agent 并行(高风险才 2 个)' },
    { title: 'Sanity', detail: '修订后 1 个 sanity-scan agent 复扫(mode=sanity)' },
  ],
}

// ── finding 输出契约(对应 review-agent-prompt.md §2.5 finding_phase_format_minimal)──
const FINDING_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['reviewer', 'round', 'findings', 'pass_skipped', 'loop_count'],
  properties: {
    reviewer: { type: 'string', description: '本 agent 扮演的视角名' },
    round: { type: 'number' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['id', 'confidence', 'severity_estimate', 'location', 'original_quote', 'observation', 'impact', 'category', 'pass_trace'],
        properties: {
          id: { type: 'string', description: 'F-001 格式,本 review 内唯一' },
          confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
          severity_estimate: { type: 'string', enum: ['p0', 'p1', 'p2', 'unsure'] },
          location: { type: 'string', description: 'plan §章节 或 文件:行,不接受"大致"' },
          original_quote: { type: 'string', description: '≤ 6 行 plan 原文' },
          observation: { type: 'string', description: '事实证据:grep 命令 + 命中数 / 字段集对比 / 真敲代码报错' },
          impact: { type: 'string', description: '不修会导致什么' },
          category: { type: 'string', enum: ['contradiction', 'design_tradeoff', 'uncertain'] },
          pass_trace: { type: 'string', description: '由哪个 Pass 发现' },
          implementer_reverse_code: { type: 'string', description: 'Pass 3 强制:自包含可跑的 30-80 行模拟代码(参考区间);其他 Pass 可省' },
        },
      },
    },
    pass_skipped: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['pass', 'reason'],
        properties: { pass: { type: 'string' }, reason: { type: 'string' } },
      },
    },
    loop_count: { type: 'string', description: '本 review 第 N 轮 / 上限 ≤ loop_max_rounds' },
    reflection: { type: 'string', description: '可选:哪些 finding 单 Pass 暴露,哪些多 Pass 交叉才暴露' },
  },
}

const SANITY_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['reviewer', 'steps', 'regressions_found'],
  properties: {
    reviewer: { type: 'string' },
    steps: {
      type: 'array',
      description: '修订后强制扫描 6 步,逐项',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['step', 'done', 'detail'],
        properties: {
          step: { type: 'string' },
          done: { type: 'boolean' },
          detail: { type: 'string', description: 'grep 命令 + 结果;跳过则写原因' },
        },
      },
    },
    regressions_found: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['location', 'issue'],
        properties: { location: { type: 'string' }, issue: { type: 'string' } },
      },
    },
  },
}

// ── 6 槽位 XML prompt 构造(对应 review-agent-prompt.md §2)──
function buildReviewPrompt(p, a) {
  const uc = a.userContext || {}
  const mustRead = (a.mustRead || ['<主 plan 文件路径>']).map((f) => `- ${f}`).join('\n')
  const mustNotRead = (a.mustNotRead || [
    '主对话历史 / 修法草案 / 用户偏好讨论原文',
    '上一轮 reviewer 的修订建议(切断 echo chamber)',
  ]).map((f) => `- ${f}`).join('\n')
  return [
    `<role>`,
    `当前你扮演 **${p.role}** 视角。`,
    `任务目标:${p.focus}`,
    `</role>`,
    ``,
    `<must_read>`,
    mustRead,
    `- 方法论:${a.methodology || 'seven-dim-review.md <core_summary>(默认只读;具体 Pass 需要时再 Read 该 Pass 章节)'}`,
    `</must_read>`,
    ``,
    `<must_not_read>`,
    mustNotRead,
    `</must_not_read>`,
    ``,
    `<output_format>`,
    `- 你必须调用 StructuredOutput 工具返回结果(字段见 schema)。`,
    `- 本阶段目标 = coverage:报告所有发现(含 uncertain / low-severity),每条标 confidence + severity_estimate;不要自我过滤,filtering 由下游 L0 + L2 做。`,
    `- location 具体到 plan §章节 或 文件:行;observation 给 grep 命令 + 命中数等事实;original_quote ≤ 6 行原文。`,
    `- Pass 3(实施者反向)的 finding 必须带 implementer_reverse_code:自包含可跑(import 全 + fixture 齐 + ≥1 条 assert/print),30-80 行是参考区间,不允许"伪代码壳"。`,
    `</output_format>`,
    ``,
    `<constraints>`,
    `- Self-claim 必须 grep 反证,不接受"读上去对"。`,
    `- 实施者反向必须真敲代码,不接受"看起来 OK"。`,
    `- category 区分 contradiction(必修)/ design_tradeoff(等用户拍板)/ uncertain(待 verify)。`,
    `- 任一 pass 不静默跳过;跳过填入 pass_skipped 并给原因。`,
    `</constraints>`,
    ``,
    `<failure_examples>`,
    a.failureExamples || '<no_prior_examples reason="首轮 review,无 archive 可抽" />',
    `</failure_examples>`,
    ``,
    `<user_context>`,
    `- 项目类型:${uc.projectType || '<未提供>'}`,
    `- 当前阶段:${uc.stage || '<未提供>'}`,
    `- 用户已拍板的 trade-off:${uc.tradeoffs || '无'}`,
    `- 用户风格偏好:${uc.stylePref || '<未提供>'}`,
    `- 本阶段已做过的反问 + 回答:${uc.priorAsks || '无'}`,
    `- 本轮已修订内容摘要:${uc.revisionSummary || '无(首轮)'}`,
    `- 本轮回环计数:第 ${a.round || 1} 轮 / 上限见 SKILL.md loop_max_rounds`,
    `</user_context>`,
  ].join('\n')
}

function buildSanityPrompt(a) {
  const uc = a.userContext || {}
  const scope = (a.sanityScope || [
    '本轮修订涉及的 plan 段落',
    'revision-checklist',
    'review-output-template.md <revision_scan_6_steps>',
  ]).map((f) => `- ${f}`).join('\n')
  return [
    `<role>`,
    `当前你扮演 **sanity-scan** 视角(修订后 L2)。`,
    `任务目标:只跑修订后强制扫描清单 6 步,不重做七维,专拦修订引入的漂移(章节漂移 / import 漂移 / 旧命名残留 / 章节号断号)。`,
    `</role>`,
    ``,
    `<must_read>`,
    scope,
    `</must_read>`,
    ``,
    `<must_not_read>`,
    `- 七维方法论全文(避免误以为要重做七维)`,
    `- 主对话历史`,
    `</must_not_read>`,
    ``,
    `<output_format>`,
    `- 调用 StructuredOutput 工具:steps 逐项给 step / done / detail(每步附 grep 命令 + 结果);regressions_found 列每处疑似漂移的 location + issue。`,
    `- 严格按 6 步,跳过也显式说明。`,
    `</output_format>`,
    ``,
    `<constraints>`,
    `- 每步给具体 grep 命令 + 结果,不接受"扫过了"。`,
    `- 只拦修订引入的回归,不扩大到全量七维。`,
    `</constraints>`,
    ``,
    `<user_context>`,
    `- 项目类型:${uc.projectType || '<未提供>'}`,
    `- 当前阶段:${uc.stage || '<未提供>'}`,
    `- 本轮已修订内容摘要:${uc.revisionSummary || '<未提供>'}`,
    `</user_context>`,
  ].join('\n')
}

// ════════════ 脚本主体 ════════════
const a = args || {}
const mode = a.mode === 'sanity' ? 'sanity' : 'finding'

if (mode === 'sanity') {
  phase('Sanity')
  log('修订后复扫:启动 1 个 sanity-scan agent(不重做七维)。')
  const scan = await agent(buildSanityPrompt(a), {
    label: 'sanity-scan',
    phase: 'Sanity',
    schema: SANITY_SCHEMA,
  })
  const regressions = (scan && scan.regressions_found) || []
  log(`sanity-scan 完成:发现 ${regressions.length} 处疑似修订引入漂移。`)
  return { mode, sanityScan: scan, regressionCount: regressions.length, agentsRun: scan ? 1 : 0 }
}

// ── finding 模式 ──
phase('Finding')
const requested = a.perspectives && a.perspectives.length
  ? a.perspectives
  : [{ role: '七维 review', focus: '对 plan 跑完整 7 个 pass(链路追踪 / Self-claim / 实施者反向 / 框架运行时 / 覆盖范围反向 / 跨层对照 / sanity scan),产 finding 阶段输出' }]

// §1 agent 数量纪律:普通 1 个 / 高风险 2 个,硬上限 2
const cap = a.isHighRisk ? 2 : 1
const finders = requested.slice(0, cap)
if (requested.length > finders.length) {
  log(`agent 数量纪律:请求 ${requested.length} 个视角,本轮只跑 ${finders.length} 个(${a.isHighRisk ? '高风险=2' : '普通=1'});其余 ${requested.length - finders.length} 个未跑,需另起一轮 review。`)
}
log(`Finding 阶段:并行启动 ${finders.length} 个独立 review agent(coverage 优先,schema 强制格式)。`)

const reports = (await parallel(
  finders.map((p) => () =>
    agent(buildReviewPrompt(p, a), {
      label: `review:${p.role}`,
      phase: 'Finding',
      schema: FINDING_SCHEMA,
    }),
  ),
)).filter(Boolean)

// 机械校验:Pass 3 finding 必须带 implementer_reverse_code(对应 §2.5)
const allFindings = []
const passThreeViolations = []
for (const r of reports) {
  for (const f of r.findings || []) {
    allFindings.push({ reviewer: r.reviewer, ...f })
    const isPass3 = /(^|[^0-9])3([^0-9]|$)|实施者反向|implementer/i.test(f.pass_trace || '')
    if (isPass3 && !f.implementer_reverse_code) {
      passThreeViolations.push({ reviewer: r.reviewer, id: f.id, location: f.location })
    }
  }
}
const p0 = allFindings.filter((f) => f.severity_estimate === 'p0').length
log(`Finding 完成:${reports.length} 个 agent 共 ${allFindings.length} 条 finding(p0 估计 ${p0});Pass3 缺 implementer_reverse_code:${passThreeViolations.length} 条。`)

return {
  mode,
  round: a.round || 1,
  agentsRun: reports.length,
  reports, // 每个 agent 的完整结构化报告(pass_skipped / loop_count / reflection)
  findings: allFindings, // 拍平的 coverage 合集,未过滤 —— 供主对话 + L0 做 Phase B
  p0EstimateCount: p0,
  passThreeViolations, // 非空 = 这些 Pass3 finding 失格,L0 应判重启该视角
}
```

---

## §6 调用示例(主对话怎么填 `args`)

**① 普通节点,首轮七维 review(1 个 agent)**:

```
Workflow({
  scriptPath: "<本模板存盘路径>",   // 或把 §5 脚本作为 script 传入
  args: {
    mode: "finding", round: 1, isHighRisk: false,
    mustRead: ["/abs/project/plans/01-data-model.md", "/abs/project/plans/02-api.md"],
    userContext: { projectType: "全栈(FastAPI+React)", stage: "步骤3 第1轮", stylePref: "严苛" },
    failureExamples: null
  }
})
```

**② 高风险节点(数据模型/API 契约),2 个视角交叉**:

```
args: {
  mode: "finding", round: 2, isHighRisk: true,
  perspectives: [
    { role: "实施者反向", focus: "用 3 种虚构新项目套 plan 找卡壳,Pass3 finding 必带真敲代码" },
    { role: "覆盖范围反向", focus: "每个机制问『不覆盖哪些场景?后果?』" }
  ],
  mustRead: ["/abs/project/plans/*.md"],
  failureExamples: "上一轮典型 P0:queryKey 漏 page_size,翻页缓存错位",
  userContext: { projectType: "全栈", stage: "步骤5 数据模型阶段", revisionSummary: "plan §3.4 重写 service 层" }
}
```

**③ 修订后 L2 复扫(1 个 sanity-scan)**:

```
args: {
  mode: "sanity",
  sanityScope: ["/abs/project/plans/03-service.md §3.4", "/abs/project/plans/archive/...-revision-checklist.md"],
  userContext: { stage: "步骤3 第2轮修订后", revisionSummary: "..." }
}
```

拿回结果后:主对话用 `findings` 做 **Phase B filtering + L0 拍板**;`passThreeViolations` 非空则判对应视角失格、按 ② 重跑该视角;按 SKILL.md step3 推进回环(P0=0 双轮验证 / ≤ `loop_max_rounds`)。

---

## §7 与 `review-agent-prompt.md` 的映射(一一对应,便于核对)

| review-agent-prompt.md | 本模板对应物 |
|---|---|
| §2 6 槽位 XML(`<role>`…`<user_context>`)| `buildReviewPrompt()` 逐槽位拼装 |
| §2.5 `<finding_phase_format_minimal>` 字段约定 | `FINDING_SCHEMA`(工具层强制)|
| §2.5 `<implementer_reverse_code>` 机械校验 | `passThreeViolations` 自动扫描标记 |
| §3.4 sanity-scan 视角 | `buildSanityPrompt()` + `SANITY_SCHEMA` |
| §4 反模式 1/2/3(无 spawn / 无槽位 / echo chamber)| **结构上不可能发生**(确定性 spawn + 进程隔离)|
| §4 反模式 4/5(漏 failure_examples / >3 agent)| 仍为内容规则:首轮自动填 `<no_prior_examples/>`;§1 硬上限 ≤ 2 |
| §1 / §1.5「对 4.7 的劝说」 | 本路径不需要(见 §0),但**原文保留**给 < 4.8 模型 |
