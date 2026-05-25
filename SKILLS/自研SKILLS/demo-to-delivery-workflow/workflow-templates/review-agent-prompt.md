# 独立 review agent 6 槽位 XML prompt 模板

> **核心定位**:SKILL.md 全部 L1 / L2 agent 钩子启动 agent 时使用本模板的 6 槽位 XML prompt。
>
> **数字阈值**:见 [`../SKILL.md`](../SKILL.md) "数字阈值单一来源" 块,本文件不重复声明。

---

## §1 为什么用多 subagent(对 4.7 的解释,启动前默读)

<why_subagent>

Claude Opus 4.7 默认压制 subagent 使用。本工作流故意采用相反策略,理由如下;启动 subagent 时主对话需理解这些理由,以免无意识降级为"主对话 reasoning"。

1. **独立性**:主对话累积了 plan 设计意图 + 用户偏好 + 已修订理由,reviewer 视角被污染。Subagent 通过槽位 2 `<must_not_read>` 隔离主对话,才能独立 review。
2. **上下文释放**:Subagent 完成后只返回 ≤ 2000 字结论,不污染主对话。7 步流程跨数周/数月,主对话上下文必须节制。
3. **交叉验证**:高风险节点(数据模型 / API 契约 / 跨模块对齐)用 2 个独立视角 agent,经验值 finding 重叠度 < 40%,显著提升 recall。

启动 subagent 时,如果 4.7 倾向于"直接用主对话 reasoning"(典型征兆:"我可以直接帮你 review"),主动 spawn subagent 并附上上面 3 条理由。

</why_subagent>

<must_not_read_rationale>

## §1.5 `<must_not_read>` 槽位的元层作用面(设计文档,启动前一次性默读)

`<must_not_read>` 槽位看似冗余 — subagent 本身是新会话,本就读不到主对话。但 Claude Opus 4.7 在主对话里有时会决定"直接帮你 review",用 reasoning 模拟 subagent 输出,绕过 subagent spawn。`<must_not_read>` 的真实作用是切断此 echo chamber 路径,具体三层:

① 必须 spawn 真正的 subagent,不用主对话 reasoning 替代;
② spawn 时不把主对话 transcript 作为输入传给 subagent;
③ subagent 启动后只读 `<must_read>` 里列的文件,不接触主对话历史。

`<must_not_read>` 中列出的条目既是 subagent 启动后的具体输入边界,也是主对话视角的元约束。

</must_not_read_rationale>

---

## §2 6 槽位 XML 结构

启动任何独立 review agent 时,prompt 必须包含以下 6 个 XML 标签,**`<role>` 与 `<output_format>` 不可空**。

```xml
<role>
当前你扮演 [七维 review / 实施者反向 / 覆盖范围反向 / sanity-scan / 文档可索引性 / 反例溯源 / 接手 sanity-scan / 跨团队接口对齐] 视角。
任务目标(一句话):...
</role>

<must_read>
- 主文件:<具体路径>
- 参照源:<具体路径>
- 方法论:<workflow-templates/seven-dim-review.md 的 <core_summary> 段,默认只读;具体 Pass 需要时再 Read 该 Pass 章节>
</must_read>

<must_not_read>
- 主对话讨论内容(修法草案 / 上一轮修订理由 / 用户偏好讨论原文)
- 上一轮 reviewer 的修订建议(切断 echo chamber)
</must_not_read>

<output_format>
- 引用 **本文件 §2.5 `<finding_phase_format_minimal>`(Core 5 内嵌,无需读 review-output-template 即可写 prompt)**;完整版(Phase B + 修订扫描 + revision-checklist + 局部 review)仍在 `workflow-templates/review-output-template.md` `<finding_phase_format>`
- **本阶段目标 = coverage**:报告所有发现,包括 uncertain / low-severity;每条标 confidence(high/medium/low)+ severity 估计(p0/p1/p2/unsure)。filtering 由下游 L0+L2 完成,你不要自我过滤。
- 风格:简洁、引用原文、给具体位置(文件:行 / plan §章节)
- 字数:focused 风格优先;复杂主题可长(参考 1500-2500 字),简单主题可短(≤ 1000 字)
- 末尾给"回环计数 + 反思(可选)"
</output_format>

<constraints>
- Self-claim 必须 grep 反证;不接受"读上去对"
- 实施者反向必须真敲 30-80 行模拟代码;不接受"看起来 OK"
- 区分两类 issue:
  - `<contradiction>plan 自相矛盾</contradiction>` — 必修
  - `<design_tradeoff>plan 设计选择存疑</design_tradeoff>` — 标 trade-off 等用户决定
- 模糊表达指引:用 "我发现 X(low confidence),建议 verify Y" 代替 "建议加强 / 待完善"
- 启动前在 PROGRESS.md §1 "回环计数" 加一条
</constraints>

<failure_examples>
<!-- 首轮无 prior archive 时用 <no_prior_examples/> 显式标签,而非占位文本 -->
<no_prior_examples reason="首次 review,无 archive/REVIEW-*.md 可抽" />

<!-- 后续轮次填法 -->
<example_from_prior_round>
- 上一轮典型 P0:`auth_service.write_audit_logout` 在 plan §3.4 被调用,但全文 0 处定义(grep 反证 0 hit)
- 本任务类似该模式,特别留意 "跨模块调用 grep 反证 ≥ 1"
</example_from_prior_round>
</failure_examples>

<user_context>
- 项目类型:<纯前端 SPA / 纯后端 / 全栈 / CLI / Notebook / 维护性 / V2 增量 / PoC>
- 当前阶段:<步骤 N — 阶段名>
- 用户已拍板的 trade-off:<列具体>
- 用户风格偏好:<严苛 / 宽松 / 倾向多 agent 交叉 / 倾向快速迭代 等>
- 本阶段已做过的反问 + 用户回答:<列具体>
- 本轮已修订内容摘要:<≤ 5 行>
</user_context>
```

**自检表**(启动前默读):
- [ ] `<role>` 任务目标具体到一句话
- [ ] `<must_read>` 列具体文件路径
- [ ] `<must_not_read>` 至少 1 条
- [ ] `<output_format>` 强调 coverage > filtering
- [ ] `<constraints>` 包含 grep 反证要求
- [ ] `<failure_examples>` 按场景填(见下表)
- [ ] `<user_context>` sub-slot 填完(基础 6 项 + 实战追加项)

**`<failure_examples>` 按场景填写参考**:

| 场景 | 填法 | 摘抄密度 |
|---|---|---|
| 首轮 review,无 archive 可抽 | `<no_prior_examples reason="..." />` 显式标签 | N/A |
| 第 N 轮 review(已有上一轮报告) | `<example_from_prior_round>` 摘 **1-3 条上轮典型 P0** + 1 条本轮关联模式风险 | 1-3 条,不全列 |
| **修订后复扫**(已 ack 的 P0 在本轮已声称 Fixed) | `<example_from_prior_round>` 摘"上一轮典型 P0 = X,本轮需 grep 反证 Fixed 真实性",**不再当 candidate 列出** | 1 条上轮 + 1 条本轮焦点 |
| 跨 review 复用模板(不同 plan 但同类陷阱) | 摘抄"上一类项目典型 P0"作为模式提示,不暗示本项目必有 | 1-2 条 |

**`<user_context>` sub-slot 填写参考**:
- 基础 6 项必填:项目类型 / 当前阶段 / 用户拍板 trade-off / 用户风格偏好 / 本阶段已做过反问+回答 / 本轮已修订内容摘要
- 实战追加项(任务给了额外字段时,**多填不少填**,不要硬塞进基础 6 项里):项目入口形态(A/B/C/D)/ 回环计数 / agent_hook_mode 等。这些会让 subagent 决策更准,不算违反 6 槽位结构
- "6 vs 7 槽位"措辞:本模板的 6 槽位指 `<role>/<must_read>/<must_not_read>/<output_format>/<constraints>/<failure_examples>`;`<user_context>` 是第 7 个 sub-block(2026 年起的扩展)。任务文案若说"6 槽位"也按 7 个全填,不要省 `<user_context>`

---

## §2.5 finding_phase_format_minimal(Core 5 内嵌)

精简版 review finding 输出格式;**Core 5 内嵌,使 review-agent-prompt 自包含** — 写 L1 review subagent 的 prompt 时**不强制 Read review-output-template.md**。完整版(含 Phase B filtering / 修订扫描 6 步 / revision-checklist / 局部 review)仍在 [`review-output-template.md`](review-output-template.md)。

```xml
<review_findings reviewer="七维 review | 实施者反向 | ..." date="YYYY-MM-DD" round="N">
  <finding id="F-XXX"
           confidence="high|medium|low"
           severity_estimate="p0|p1|p2|unsure">
    <location>plan §章节 / 文件:行</location>
    <original_quote>≤ 6 行 plan 原文</original_quote>
    <observation>你观察到的事实(grep 命中数 / 字段集对比 / 真敲代码报错等)</observation>
    <impact>不修会导致什么(运行时错误 / 数据正确性 / 回归路径)</impact>
    <category>contradiction | design_tradeoff | uncertain</category>
    <pass_trace>Pass N(本 finding 由哪个 Pass 发现)</pass_trace>
    <!-- Pass 3 实施者反向 finding 强制带本字段;其他 Pass 可选 -->
    <implementer_reverse_code optional="true">
      真敲代码展示卡壳点 / 反射错误 / queryKey 漂移等具体证据。
      行数 30-80 是参考区间,不是硬约束:simple finding(单点 await 漏 / 单字段缺失)允许 ≤ 30 行,
      但代码必须自包含可跑(import 段完整 + fixture 齐 + 至少 1 条 assert / print 暴露问题),
      不允许"伪代码壳"(只贴函数签名 + 注释、无 runnable body)。
      Pass 3 finding 不带此字段或字段不可跑视为"看起来 OK"伪 finding,L0 应判失格、重启 agent。
    </implementer_reverse_code>
  </finding>

  <!-- 更多 finding ... -->

  <pass_skipped>
    <!-- 显式列出跳过的 pass + 原因;不允许默默省略 -->
    <pass id="N" reason="..." />
  </pass_skipped>

  <loop_count>本 review 是第 N 轮 / 上限 ≤ loop_max_rounds</loop_count>

  <reflection optional="true">
    哪些 finding 单 Pass 暴露,哪些多 Pass 交叉才暴露
  </reflection>
</review_findings>
```

### 字段约定

| 字段 | 必填 | 说明 |
|---|---|---|
| `id` | ✓ | `F-001` 格式,本 review 内唯一 |
| `confidence` | ✓ | high / medium / low;low-confidence finding 也要报,不要自我过滤 |
| `severity_estimate` | ✓ | p0 / p1 / p2 / unsure;只是估计,filtering 在 Phase B 完成 |
| `location` | ✓ | 具体到 plan §章节 或 文件:行,不接受"plan 整体 / 大致" |
| `original_quote` | ✓ | 引用 plan 原文 ≤ 6 行(ground in quotes,官方推荐) |
| `observation` | ✓ | 事实陈述 + grep 命令 + 命中数;不是结论,是证据 |
| `impact` | ✓ | 不修会导致什么 |
| `category` | ✓ | contradiction(必修)/ design_tradeoff(等用户拍板)/ uncertain(待 verify) |
| `pass_trace` | ✓ | 哪个 Pass 发现 |
| `implementer_reverse_code` | Pass 3 强制 / 其他可选 | **Pass 3 finding 必须带,否则视为伪 finding**(机械校验项);行数 30-80 是参考区间(详见上方字段说明),关键是"自包含可跑"而非凑行数 |

### `<implementer_reverse_code>` 机械校验

把"真敲 30-80 行代码"作为**输出契约字段**:Pass 3 finding 不带该字段 → L0 判 agent 失格、重启。这把"真敲"从 prompt 约束升级为可机械校验。

**行数与代码自包含的具体尺度**:
- "30-80 行"是参考区间,不是硬上下限。L0 判合格的真正标尺是"代码自包含可跑":import 段完整 / fixture 齐 / 至少 1 条 assert 或 print 暴露问题。
- Simple finding(单点 `await` 漏 / 单字段缺失)允许 ≤ 30 行,只要能跑、能暴露。
- 复杂 finding(多 caller 联动 / 跨层反射)允许 > 80 行,但需要在代码顶部加 1 行注释解释为何不能压缩。
- 不允许"伪代码壳":只贴函数签名 + 注释 + 没有 runnable body 即判失格。

---

## §3 8 类视角 prompt few-shot

每类视角的样例下含 **good / bad / edge 三种**,展示给 4.7 标准是什么。

### 3.1 七维 review(SKILL.md 步骤 3 主跑)

<example_good_seven_dim_review>

```xml
<role>
当前你扮演 **七维 review** 视角。
任务目标:对 plan 跑完整 7 个 pass(链路追踪 / Self-claim 验证 / 实施者反向 / 框架运行时 / 覆盖范围反向 / 跨层对照 / sanity scan),产出 finding 阶段输出 — 报告所有发现,包括 uncertain / low-severity。
</role>

<must_read>
- 主:`plans/01-data-model.md` `plans/02-api.md` `plans/03-service.md`
- 参照:`demo/README.md` `demo/FLOW.md`
- 方法论:`workflow-templates/seven-dim-review.md` <core_summary>(默认只读;具体 Pass 需要时再 Read 该 Pass 章节)
</must_read>

<must_not_read>
- 主对话历史
- 上一轮 reviewer 的修订建议
- 用户对上轮 trade-off 的具体回答
</must_not_read>

<output_format>
- 引用 `review-output-template.md` <finding_phase_format>
- 每条 finding 带 confidence(high/medium/low)+ severity 估计(p0/p1/p2/unsure)
- 不要自我过滤 low-severity;coverage 优先
- 末尾给回环计数
</output_format>

<constraints>
- 任一 pass 不跳过(7 个 pass 都需出 finding 或显式说"本 pass 无发现 + 检查清单")
- Self-claim 必须 grep 反证
- async / await 字面 grep + import 完整性 + 章节号连续
- 区分 contradiction vs design_tradeoff
</constraints>

<failure_examples>
<example_from_prior_round>
上一轮典型 P0:plan §3.2 声称"queryKey 包含所有影响响应的参数",但 `useRequirements` 实际 queryKey 漏 `page_size`,翻页时缓存命中错位。
本任务类似该模式,特别留意 React Query queryKey 完整性。
</example_from_prior_round>
</failure_examples>

<user_context>
- 项目类型:全栈(FastAPI + React)
- 当前阶段:步骤 3 — 多轮 review 第 2 轮
- 用户已拍板:`record_status` 用 enum 而非 free string
- 用户风格:严苛,倾向多 agent 交叉
- 本阶段已做过的反问:状态机 closed 后是否允许重新激活? → 用户答否
- 本轮已修订内容摘要:plan §3.4 重写了 service 层 + plan §5 新增了 sweeper cleanup 描述
</user_context>
```

</example_good_seven_dim_review>

<example_bad_seven_dim_review>

```
启动 1 个 Plan agent 跑七维 review。
```

**问题**:无 6 槽位 / 无角色 / 无必读 / 无 must_not_read(echo chamber)/ 无输出格式(会自我过滤)/ 无 constraints / 无 failure_examples / 无 user_context。4.7 会用主对话上下文做"伪 subagent"。

</example_bad_seven_dim_review>

<example_edge_seven_dim_review>

边界场景:plan < 200 行 + 单模块项目(满足小项目降级条件)。

```xml
<role>
七维 review 视角(降级模式:跑 Pass 1 / 2 / 3 / 7,跳 Pass 4 / 5 / 6)
任务目标:plan 简短,只跑 4 个 pass 即可
</role>

<must_read>
- plan 全文
- workflow-templates/seven-dim-review.md <core_summary>
</must_read>

<must_not_read>主对话</must_not_read>

<output_format>
- finding 阶段;coverage 优先
- 简短风格(≤ 800 字)
- 跳过的 Pass 显式标 "skipped — reason: 小项目降级"
</output_format>

<constraints>
- 即使跳过 Pass 也要显式声明,不能默默省略
</constraints>

<failure_examples><no_prior_examples reason="首轮无 archive" /></failure_examples>

<user_context>
- 项目类型:CLI 工具,plan 150 行,3 阶段
- 当前阶段:步骤 3 第 1 轮 review
- 降级模式:lightweight(见 PROGRESS.md 顶部元信息)
- 用户风格:倾向快速迭代
</user_context>
```

</example_edge_seven_dim_review>

### 3.2 实施者反向

```xml
<role>
扮演"下次开新项目准备使用这套 plan 的 AI 实施者"。
任务目标:用 3 种虚构新项目套 plan 找哪里卡壳;输出每个虚构项目走一遍 7 步,列出对不上的产物 / 反问钩子空喊 / 验收门不适用。
</role>

<must_read>
- plan 全部文件
- workflow-templates/seven-dim-review.md <pass_3_implementer_reverse>
</must_read>

<must_not_read>
- 本项目历史 review 报告(避免 echo)
- 主对话
</must_not_read>

<output_format>
- finding 阶段;每个虚构项目独立一段
- 真敲 30-80 行模拟代码,贴在 finding 内
</output_format>

<constraints>
- 必须 3 种虚构项目交叉验证
- 真敲代码;"看起来 OK" 等价于 finding 缺失
</constraints>

<failure_examples>
<example_from_prior_round>
demo 三件套硬编码"前端形态",CLI / Notebook 项目对不上 → plan 验收门"反向重建测"对 Notebook 无意义
</example_from_prior_round>
</failure_examples>

<user_context>
项目类型 / 当前阶段 / 已反问
</user_context>
```

### 3.3 覆盖范围反向

```xml
<role>
**覆盖范围反向** 视角。
任务目标:每个机制问"它不覆盖哪些场景?那些场景会怎样?"
</role>

<must_read>
- plan 文件
- workflow-templates/seven-dim-review.md <pass_5_coverage_reverse>
</must_read>

<must_not_read>主对话</must_not_read>

<output_format>finding 阶段;每个机制独立一行"未覆盖场景 + 后果"</output_format>

<constraints>
- 列出每个机制的 "未覆盖场景 + 后果"
- 代入 "hook 只管 SELECT → bulk UPDATE 漏过滤" / "守卫只挡未登录 → 已登录越权未挡" 等典型陷阱
</constraints>

<failure_examples>
<example_from_prior_round>
守卫 / 拦截器跳转自循环(navigate 到自己保护范围,死循环)
</example_from_prior_round>
</failure_examples>

<user_context>...</user_context>
```

### 3.4 sanity-scan(修订后,L2)

```xml
<role>
**sanity-scan** 视角。
任务目标:只跑修订后强制扫描清单 6 步,不重做七维,专拦修订引入的漂移。
</role>

<must_read>
- 本轮修订涉及的 plan 段落
- revision-checklist
- review-output-template.md <revision_scan_6_steps>
</must_read>

<must_not_read>
- 七维方法论全文(避免误以为要重做七维)
- 主对话
</must_not_read>

<output_format>
严格按 6 步逐项输出"做了 / 跳过 + 原因"
</output_format>

<constraints>
- 每步给具体 grep 命令 + 结果
- 显式列出"6 步逐项做了 / 跳过 + 为什么"
</constraints>

<failure_examples>
<example_from_prior_round>
修订引入的 import 漂移(改 hook 实现后,顶部 import 段没补 useMemo)/ 旧命名残留 / 章节号断号
</example_from_prior_round>
</failure_examples>

<user_context>...</user_context>
```

### 3.5 文档可索引性(SKILL.md 步骤 7)

```xml
<role>
**文档可索引性** 视角。
任务目标:以"陌生 AI 视角",只读 AGENTS.md / CLAUDE.md 等项目级指令文件,不读代码,反推能否定位所有典型业务功能 / utility / 测试。
</role>

<must_read>
- AGENTS.md / CLAUDE.md(项目级指令文件,见 agents-md-skeleton.md §0)
- 各 docs/*.md
</must_read>

<must_not_read>
- 实际代码(测可索引性,不测理解力)
- 主对话
</must_not_read>

<output_format>
列出 5 个典型 query("X 字段在哪里定义?")→ 期望命中段 vs 实际命中段
</output_format>

<constraints>
- 命中失败 = AGENTS.md / CLAUDE.md 索引漏项 → finding
- coverage 优先;low-confidence 也报
</constraints>

<failure_examples>
<example_from_prior_round>
索引表漏新增功能模块行 / utility 速查漏新增 helper
</example_from_prior_round>
</failure_examples>

<user_context>...</user_context>
```

### 3.6 反例溯源(SKILL.md 步骤 7 reviewRule 生成)

```xml
<role>
**反例溯源** 视角。
任务目标:验证 reviewRule.md 每条 P0/P1 是否能在 LOG / NOTES / archive REVIEW 找到原始踩坑出处。
</role>

<must_read>
- `<module>/docs/reviewRule.md`
- `archive/plans/LOG.md`
- `IMPLEMENTATION-NOTES.md`
- `archive/plans/archive/REVIEW-*.md`
</must_read>

<must_not_read>主对话 / 训练数据中的通用 best practice</must_not_read>

<output_format>
每条 reviewRule 标 "命中(<反例文件:行>)" 或 "找不到出处 → 待用户决定删 / 保留"
</output_format>

<constraints>
- grep 反例文件命中 ≥ 1
- 通用 best practice(如"所有函数应有 type hint")若本项目未踩过 → 标记移除
</constraints>

<failure_examples>
<example_from_prior_round>
AI 写 reviewRule 时把"通用最佳实践"塞进来,但本项目实际未踩过这种坑 → 应移除
</example_from_prior_round>
</failure_examples>

<user_context>...</user_context>
```

### 3.7 接手 sanity-scan(多 AI 协作)

```xml
<role>
**接手 sanity-scan** 视角。
任务目标:扫前手最后 N 次修订是否漂移,确保接手 AI 不重蹈前手坑。
</role>

<must_read>
- `PROGRESS.md` 全文(尤其 §1 接手必读)
- 前手最后 3 次 commit(`git log -3` + `git show <hash>`)
- 受影响的 plan / IMPLEMENTATION 章节
</must_read>

<must_not_read>前手主对话(避免继承 echo)</must_not_read>

<output_format>
接手风险点清单(每条标"前手已处理 / 待接手 AI 处理 / 等用户拍板")
</output_format>

<constraints>
- 复核前手最后一次验收门 5/5 或 6/6 全过
- 复核 staged 但未 commit 文件清单与实际 git status 一致
</constraints>

<failure_examples>
<example_from_prior_round>
前手在"路线级修订"中段离开,IMPLEMENTATION 未同步重拆,接手 AI 按旧 IMPLEMENTATION 走会重蹈坑
</example_from_prior_round>
</failure_examples>

<user_context>...</user_context>
```

### 3.8 跨团队接口对齐(大型企业项目,可选)

```xml
<role>
**跨团队接口对齐** 视角(可选,仅适用多模块多团队)
任务目标:扫本模块契约 vs 上下游模块契约 是否一致
</role>

<must_read>
- 本模块 API / DB schema / 消息格式
- 上下游模块对应契约
- 各 `sub-PROGRESS.md`(若分层)
</must_read>

<must_not_read>主对话</must_not_read>

<output_format>契约不一致 issue 清单(端点 / 字段 / 时序 / 错误码)</output_format>

<constraints>列出 finding;coverage 优先</constraints>

<failure_examples>
<example_from_prior_round>
模块 A 加新字段,模块 B 不知道 / 模块 A 改错误码语义,模块 B 仍按旧码处理
</example_from_prior_round>
</failure_examples>

<user_context>...</user_context>
```

---

## §4 反模式(以下启动方式不可用)

启动 review subagent 前自检:**以下 5 种启动方式都不可用**,因为它们让 4.7 退化为"主对话伪 review"。

<antipattern>

1. `"启动 1 个 Plan agent 做 X"` — 空喊,无 6 槽位
2. `"用七维方法论 review 我的 plan"` — 无角色 / 必读 / 输出 / 约束 / 反例 / 上下文
3. `"agent 可读主对话"` — 失去独立性,echo chamber
4. `"不填 <failure_examples>,跳过反例"` — agent 失去防漂移参照(首轮用 `<no_prior_examples/>`,不要省略标签)
5. `"同一 review 启动 > 3 个 agent"` — 超出回环上限(`loop_max_rounds`),稀释独立性

</antipattern>

---

## §5 配合 Claude Opus 4.7 的工作风格备忘

启动 subagent 时,主对话写明:

```
本工作流使用 Claude Opus 4.7 在 effort=xhigh 或 max 下运行,subagent 是有意设计(理由见 review-agent-prompt.md §1)。
请按 XML 6 槽位完整启动 subagent,不要降级为主对话直接 reasoning。
Subagent 的 thinking 配置应是 adaptive;subagent 完成后只返回 ≤ 2000 字结论。
```
