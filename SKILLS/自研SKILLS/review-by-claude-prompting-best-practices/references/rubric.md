# 提示词评审 Rubric

这是 [best-practices.md](best-practices.md) 浓缩出来的可执行清单。审查任何提示词时,逐项检查并记录证据。如需查证某条规则的原始上下文,回到 best-practices.md 对应章节(Part 1 通用 / Part 2 Fable 5 专属 / Part 3 Opus 4.8 专属)。

**目标模型(target model)**:绝大多数条目跨模型通用(官方明确 General principles "apply to all current models")。少数条目(I2/I3、J3、K 表标注「模型条件」的行)的判定依赖**被审 prompt 将来运行在哪个模型上**,而不是执行审查的模型 —— 按 SKILL.md 步骤 1.3 确定的目标模型判;未确定时默认按最新一代(Claude Fable 5)判,并在报告头部注明该假设。

---

## A. 清晰与具体性 (Clarity & Specificity)

**A1. 输出格式与约束是否明确?**
- 期望产出形式(报告/JSON/Markdown/纯文本)、长度、字段、结构是否写清楚?
- 反例:`"创建一个分析仪表盘"`
- 正例:`"创建一个分析仪表盘。包含尽可能多的相关功能和交互。超出基础要求,实现一个功能完整的版本。"`

**A2. 顺序敏感的步骤是否用编号列出?**
- 当步骤顺序或完整性重要时,使用 numbered list / bullet points。

**A3. "陌生同事测试":如果一个不熟悉业务的同事拿到这段提示词,他能照做吗?**
- 这是 Claude 官方提出的 "golden rule"。任何让外人困惑的地方,模型也会困惑。

**A4. 是否使用 Modifier 语言(quality / completeness modifier)?**
- 当任务希望模型"超出基础"做一个完整实现时,加 modifier 显著提升输出质量。
- 反例:`"Create an analytics dashboard"`
- 正例:`"Create an analytics dashboard. **Include as many relevant features and interactions as possible. Go beyond the basics to create a fully-featured implementation.**"`
- 出处:Claude 官方 best-practices.md → "Migration considerations" 与 "Be clear and direct" 章节。这是 4.6+ 模型上提升完整度最有效的单条改写之一。

**A5. 需要广泛应用的指令,是否显式声明了作用域?**
- 新模型(Opus 4.7+,含 4.8、Fable 5)字面遵循指令,不会自动从"一项"泛化到"全部",也不会推断你没提的需求。
- 反例:只给一个 section 的处理示范,却默认模型会套用到所有 section。
- 正例:`"对每个 section 都应用这个格式,而不只是第一个。"`
- 出处:best-practices.md → Part 3 "More literal instruction following";Fable 5 指令遵循进一步增强(Part 2 "Strong instruction following":一句简短指令即可替代逐项枚举)。

---

## B. 解释 Why (Motivation / Reasoning)

**B1. 关键指令是否附带"为什么"?**
- 反例:`"绝对不要使用省略号"`
- 正例:`"你的回答会被语音引擎朗读,所以不要使用省略号 —— 语音引擎不知道怎么读它们。"`
- 原因:模型能从解释中泛化到边界情况,只给规则反而僵化。

**B2. 是否过度使用 ALL CAPS MUST / NEVER?**
- Claude 4.5+(含 Opus 4.8、Fable 5)已经对系统提示非常敏感,过于激烈的措辞反而会触发"过度遵从",在边缘场景上失灵。
- 倾向:用"自然语气 + 解释 why",而不是堆砌大写禁令。
- Fable 5 加码依据:官方原话 "Skills developed for prior models are often too prescriptive for Claude Fable 5 and can degrade output quality. Review and consider removing older instructions if default performance is better."(Part 2 → Recommended scaffolding changes)。目标模型为 Fable 5 时,旧时代的高压/微指令应主动建议删减,而不只是降调。

---

## C. 示例 (Examples / Few-shot)

**C1. 对格式/风格敏感的任务是否提供了 3-5 个示例?**
- 少样本示例是最可靠的输出控制手段之一。

**C2. 示例是否用 `<example>` / `<examples>` 标签包裹?**
- 让模型能区分示例与指令本身。

**C3. 示例是否多样并覆盖边界情况?**
- 单一示例会让模型抓住意外的模式。

---

## D. XML 结构化 (XML Tags)

**D1. 复杂提示词(指令 + 上下文 + 示例 + 变量输入混杂)是否用 XML 标签分块?**
- 例如 `<instructions>`、`<context>`、`<input>`。

**D2. 标签命名是否一致、有描述性?**

**D3. 多文档输入是否用 `<documents>` / `<document index="n">` 结构?**

---

## E. 输出格式控制 (Format Control)

**E1. 是否"说要做什么"而不是"说不要做什么"?**
- 反例:`"不要使用 markdown"`
- 正例:`"用流畅的散文段落组织你的回答。"`

**E2. 提示词本身的风格是否与期望输出一致?**
- 如果想要少 markdown 的输出,提示词本身也少用 markdown。

**E3. 是否使用 XML 标签作为格式指示符?**
- 例如 `<smoothly_flowing_prose_paragraphs>` 包裹散文段。

---

## F. 角色设定 (Role)

**F1. system prompt 中是否给模型设定了清晰的角色?**
- 哪怕一句话也会显著影响行为。

---

## G. 长上下文处理 (Long Context, >20k tokens)

**G1. 长文档是否放在 prompt 顶部、query/指令/示例之前?**
- 测试显示这能提升最高 30% 的回答质量。

**G2. 多文档是否用 `<document>` + `<source>` + `<document_content>` 子标签结构化?**

**G3. 是否要求模型先"提取相关引用"再回答?**
- 用 `<quotes>` 标签包裹模型摘录的相关片段,降噪。

---

## H. 工具使用 (Tool Use)

**H1. 想让模型采取行动时,措辞是否明确(改 vs 建议)?**
- 反例:`"你能建议一些改进吗?"` → 模型只会建议
- 正例:`"修改这个函数以提升性能。"`

**H2. 并发工具调用是否被鼓励/约束?**
- 高效场景:加入 `<use_parallel_tool_calls>` 段引导并行。
- 稳定场景:明确要求串行。

**H3. 是否过度提示工具使用?**
- 4.5+ 之后模型已经不会"过度不触发";Opus 4.8 进一步改善了工具触发(修了 4.7"漏掉该调的工具"的问题),更不需要靠强语气补漏;Fable 5 指令遵循更强,高压措辞同样应删(见 B2 的 Fable 5 加码依据)。
- `"CRITICAL: You MUST use this tool when..."` 这种写法在新模型上反而会过触发。当年为「补漏」加的高压用工具指令,现在更该删,改成自然语气 `"Use this tool when..."`。
- 模型条件(Opus 4.8):它倾向"先推理后调工具"(favor reasoning over tool calls),想要更多工具调用时官方首选杠杆是调高 effort,其次才是在 prompt 里清楚描述"何时、为何、如何"用该工具 —— 仍然不是高压措辞(Part 3 → Tool use triggering)。

---

## I. Thinking / 推理 (Thinking & Effort)

**I1. 简单任务是否被赋予了不必要的"think hard"指令?**
- 这会导致 token 浪费和延迟膨胀。

**I2. 复杂任务是否给了适合的思考引导(而非死板的 step-by-step 模板)?**
- 通用引导(`"think thoroughly"`)往往比手写 step-by-step 更好。
- 关键词:Claude 4.7+(含 Opus 4.8)默认 thinking 关闭(不显式开 adaptive 就不思考),"关闭态对 'think' 一词敏感"这条因此更常触及 —— 可换用 "consider"、"evaluate"、"reason through"。
- 模型条件(Fable 5):**仅支持 adaptive thinking**(无 extended thinking / `budget_tokens`),且 thinking 输出**只有 summarized 摘要**,应用侧拿不到完整思考原文(出处:Part 2 开头 Note)。审查时连带检查:prompt 是否假设"能读到/能要求模型展示完整推理"—— 这在 Fable 5 上既不成立,还可能触发 K 表「要求复述内部推理」反模式。

**I3. 是否用泛泛高压词硬催思考深度?**
- 评审重点(prompt 文本层面,这才是本条依据):有没有"想深一点 / think very hard / 务必深入思考"这类泛泛高压词,企图靠文字催出更深推理。这类写法在新模型上既无效又可能扰乱(4.8 档位重标定后更明显)→ ⚠️。
- 不是反模式(别误判):thinking 关闭时(Opus 4.8 / Claude Code 默认由 effort 管),官方把 manual CoT 当有效 fallback —— 让模型 step-by-step 想是推荐做法;effort 被迫锁在 `low` 时,一句"针对性"(非泛泛)的多步引导也是官方解法。这些应保留,不算违规。
- 建议项(非评分依据):若确实需要更深推理,真正的杠杆是 effort 而非 prompt 文字 —— 可**顺带提醒**调用方(Claude Code:`/effort` / `--effort` / settings.json `effortLevel`;API:`output_config.effort`)。官方各模型的 effort 建议不同:Opus 4.8 coding/agentic 从 `xhigh` 起步、智力敏感场景至少 `high`(Part 3 → Calibrating effort);Fable 5 大多数任务默认 `high`,最能力敏感的场景才用 `xhigh`,且低档位表现常优于上代的 `xhigh`(Part 2 → Consider all effort levels)。但 effort 是运行时配置、审查者通常无法替 prompt 作者决定,**只作一句建议带过,不作为本条评分依据,更不要因此给 ❌**。

**I4. 是否要求模型在结束前自检?**
- `"在结束前,用 [test criteria] 验证你的答案。"` 能可靠捕获错误。

---

## J. Agentic 系统(适用时)

**J1. 长任务是否有 state tracking 引导?**
- 是否引导模型用 git / tests.json / progress.txt 保存进度?

**J2. 是否提示模型注意可逆性?**
- 危险操作(`rm -rf`、`force push`、`reset --hard`)是否要求用户确认?

**J3. Subagent 委派是否有明确指引?(模型条件,按目标模型分叉)**
- 共同点:无论哪代模型,官方都建议在 prompt 里明确"什么时候该/不该委派",而不是放任默认行为。
- 目标模型为 Opus 4.6:倾向**过度** spawn(直接 grep 更快的场景也开 subagent),审查点是"有没有写明什么场景不要 spawn"(Part 1 → Subagent orchestration)。
- 目标模型为 Opus 4.8:默认 spawn **偏少**,需要时应显式引导何时值得开(Part 3 → Controlling subagent spawning)。
- 目标模型为 Fable 5:官方口径转为**鼓励**——"Use subagents frequently",并建议 orchestrator 与 subagent 之间**异步通信**(不阻塞等待)、复用长寿命 subagent 省 cache(Part 2 → Parallel subagents)。此时"一刀切节制 subagent"的旧指令反而是 finding;审查点变为"是否给了委派时机指引 + 是否允许异步/并行"。

**J4. 是否引导清理临时文件?**

**J5. 长程自治任务是否要求"进度声明落地到证据"?(Fable 5 重点,通用受益)**
- 长跑 agent prompt 应要求:汇报进度前,把每条声明对照本会话的实际 tool result;未验证的事就明说未验证。
- 官方实测:这条提示几乎消除了编造的状态汇报("nearly eliminated fabricated status reports")。
- 参考模板:`"Before reporting progress, audit each claim against a tool result from this session. Only report work you can point to evidence for; if something is not yet verified, say so explicitly."`
- 出处:Part 2 → Ground progress claims during long runs。

**J6. 跨会话/长跑 agent 是否提供了 memory 机制引导?(Fable 5 重点)**
- Fable 5 在能记录并引用既往经验时表现显著更好;一个 Markdown 笔记目录即可。
- 审查点:多次运行、跨会话迭代类 prompt,是否指明"把教训写到哪、一个文件一条、更新而非重复、删错误笔记"。
- 出处:Part 2 → Construct a memory system。缺失时标 ⚠️(不是 ❌ —— 属于增益项)。

**J7. 是否向模型暴露剩余上下文/token 倒计时?**
- Fable 5 看到剩余 token 倒计时,可能提前收尾、自行总结交接或建议开新会话。harness 能不显示就不显示;必须显示时加一句安抚(`"You have ample context remaining. Do not stop, summarize, or suggest a new session on account of context limits."`)。
- 出处:Part 2 → Rare cases of context-budget concern。注意与 Part 1 的 context awareness 指引(4.5/4.6 模型「不要因预算提前收尾 + 临近时存进度」)配合理解:两者都指向"别让模型因预算焦虑缩水工作"。

---

## K. 反模式速查 (Anti-patterns to Flag)

每条「快筛信号」给出可机械执行的 grep / 计数判定,作为人工对照之外的兜底。SKILL.md 步骤 2.4 会跑这些 grep。

**重要:用词级计数 `grep -o ... | wc -l`,不用行计数 `grep -c`** —— 后者在单行长 prompt 上会假阴性(一行内 5 次 MUST 仍只计 1)。

| 反模式 | 现象 | 快筛信号(grep / 计数) | 建议做法 |
|---|---|---|---|
| 模糊指令 | `"创建仪表盘"` | 主指令缺 modifier(无"包含..."/"include...") | 加 modifier:`"包含尽可能多的相关功能..."` |
| 纯否定指令 | `"不要..."` `"绝不..."` | `grep -oiE "不要\|不能\|绝不\|不得\|don't\|do not\|never" \| wc -l` ≥ 3 | 改为正向描述 + why |
| 高压大写 | 大段 `MUST`/`NEVER`/`CRITICAL` | `grep -oE "MUST\|NEVER\|CRITICAL\|ALWAYS\|REQUIRED" \| wc -l` ≥ 5 | 自然语气 + 解释原因 |
| 无理由规则 | 干瘪命令 | 强语气词(MUST/NEVER/必须/绝对)后 50 字内无 "because"/"why"/"因为"/"原因" | 附带"为什么这么做" |
| 无示例的格式任务 | 期望 JSON/特定结构却没示例 | 提到 JSON / YAML / 特定 schema,但全文无 `<example>` 标签或代码块示例 | 加 3-5 个 `<example>` |
| 模糊动词 | "扫描"、"处理"、"分析" 后无具体工具/命令 | `grep -oiE "扫描\|处理\|分析\|检查"` 命中后,看后续 50 字内是否有具体动作(Read/Edit/grep/bash 等) | 拆为可执行步骤,动词配工具 |
| 临时文件未清理 | 创建 `/tmp/...` 但流程末尾无 `rm` | `grep -o "/tmp/" \| wc -l` > 0 且 `grep -oE "rm \|rm -" \| wc -l` = 0 | 在结尾加 cleanup 段 |
| 防御性过度 | 让模型在内部代码加 try/catch、validation | 看到 "always validate"/"always check"/"defensive" 等关键词 | 只在系统边界校验 |
| 鼓励过度全面 | `"尽可能详尽地调研..."` / `"ALWAYS be thorough"` | `grep -oiE "详尽\|exhaustive\|comprehensive\|as much as possible\|thoroughly\|ALWAYS .{0,20}(be\|do\|use)" \| wc -l` ≥ 1 | 4.6+ 已默认彻底,改为 targeted instruction |
| 鼓励过度工程 | 让模型主动加抽象/重构 | `grep -E "refactor\|abstract\|generalize\|future-proof"` 且无 "only when needed" 限定 | 加入 anti-overengineering 段 |
| Prefilled 响应 | 用 assistant 消息预填强制格式 | 看 messages 数组里末位是否为 assistant role(API 场景) | 改用 structured outputs 或 XML 标签 |
| Step-by-step 死板模板 | 替代模型自身 reasoning | 工作流型 prompt 例外(那是 by design),通用 prompt 中若 step 1/2/3 全是固定指令 → 标记 | 用通用引导 + adaptive thinking |
| 多文档无结构 | 一大段裸文本拼接 | 多份 input 但全文无 `<document>` / `<documents>` 标签 | `<documents>` + `<document index>` |
| 长文档放底部 | 文档在 query 之后 | 长 input(>2k 字)出现在指令/问题之后 | 长文档放顶,query 放底 |
| **内容过稀** | 文件本身缺少必要章节 | **文件长度 < 500 字节 且 上述兜底信号全部 = 0** → 不是"写得对",而是"还没写完" | 触发 ❌,以 rubric A-F 维度逐项要求补章节(description / 工作流 / 输出 / 示例 / 角色 / why) |
| 作用域未声明 | 给单项示范却想让模型套用到全部 | 出现 "every/all/各/所有/每个" 类广泛意图,但只举了单个示例或只描述了一处 | 显式写明 scope:"对每个…都…,而非只第一个"(新模型字面遵循,不会自动泛化) |
| prompt 硬催思考 | 用泛泛高压词催"想更深" | `grep -oiE "think (very )?(hard\|deeply)\|想.{0,4}深\|深入思考\|务必.{0,6}思考" \| wc -l` ≥ 1 | 先分场景:thinking 关闭 / effort 锁死 → 保留针对性多步引导(manual CoT 是官方 fallback,勿误删);否则标 ⚠️ 删泛泛催词。调高 effort 仅作建议带过、非评分依据 |
| **要求复述内部推理**(模型条件) | 让模型在回复正文中展示/转写/解释它的内部思考 | `grep -oiE "show your (thinking\|reasoning)\|explain your (internal \|chain.of.thought\|内部)?reasoning\|transcribe.{0,20}(thinking\|reasoning)\|复述.{0,8}(推理\|思考)\|展示.{0,6}思考过程\|输出.{0,6}思考过程\|把.{0,8}推理过程" \| wc -l` ≥ 1 | 目标模型为 Fable 5 → ❌:触发 `reasoning_extraction` refusal、推高 fallback(Part 2 → Recommended scaffolding changes);其他模型 → ⚠️。替代:读 adaptive thinking 的结构化 `thinking` 块,或用 send-to-user 工具汇报进度。注意区分:manual CoT("先想再答,推理放 `<thinking>` 标签")是 Part 1 认可的 fallback,不算违规;违规的是"把你内部的思考过程原样给我看" |
| **旧模型时代过度规定性**(模型条件) | 为老模型写的微步骤/高压 skill 原样用于 Fable 5 | 复用 N_CAPS / N_NEG 信号 + 通篇 step 1/2/3 微指令密度;结合目标模型判断 | 目标模型为 Fable 5 → 引官方原话建议**删减**而非仅降调:"Skills developed for prior models are often too prescriptive for Claude Fable 5 and can degrade output quality"(Part 2)。先试默认行为,默认更好就删旧指令 |
| **暴露 token 倒计时** | prompt/harness 给模型看剩余上下文计数 | `grep -oiE "remaining (tokens\|context)\|tokens? (left\|remaining)\|剩余.{0,6}(token\|上下文\|预算)" \| wc -l` ≥ 1 且无安抚语 | Fable 5 见倒计时可能提前收尾/建议开新会话(Part 2)→ ⚠️;能不显示就不显示,必须显示则加 `"You have ample context remaining..."` 安抚段 |

---

## 评分维度速记

每条规则 review 时给出:
- **状态**: ✅ 做得好 / ⚠️ 有改进空间 / ❌ 违反最佳实践 / N/A 不适用
- **证据**: 引用提示词原文片段(最多 100 字)
- **why**: 引用 Rubric 对应条目的原因
- **建议改写**: 给出具体修改后的片段(不要只说"改一下")

标注「模型条件」的条目(I2/I3、J3、K 表对应行),判定和建议改写都要基于**目标模型**(被审 prompt 实际运行的模型,见 SKILL.md 步骤 1.3),并在 finding 里写明"此判定基于目标模型为 X"。

---

## 写评审报告的防御性原则

这几条不针对被审查的提示词,而是约束评审者自己,防止"为了证明 rubric 有用而硬找问题":

1. **如果一条规则没有被违反,不要把它放进 finding 列表**。可以在维度得分表里标 ✅ 或 N/A,但不要在"❌ 违反"或"⚠️ 改进空间"段强行编一个低权重问题。
2. **总体评估要与 finding 数量校准**。如果 ❌ 严重违反项 ≤ 1,且 ✅ 项 ≥ 5,「总体评估」一行应当包含正向定性(例如"整体写得不错"、"质量较高,主要可优化点是 X")。
3. **不要把"风格偏好"包装成"违反最佳实践"**。如果一个写法 best-practices.md 没有点名反对,只是你觉得不够好,标 ⚠️,不要标 ❌。
4. **控制组测试**:写完报告后扫一眼 —— 如果换一个写得相对好的提示词来审,这份报告的语气会不会过度负面?如果会,降级 ⚠️/⚠️/❌ 的分布。
