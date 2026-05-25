# 提示词评审 Rubric

这是 [best-practices.md](best-practices.md) 浓缩出来的可执行清单。审查任何提示词时,逐项检查并记录证据。如需查证某条规则的原始上下文,回到 best-practices.md 对应章节。

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

---

## B. 解释 Why (Motivation / Reasoning)

**B1. 关键指令是否附带"为什么"?**
- 反例:`"绝对不要使用省略号"`
- 正例:`"你的回答会被语音引擎朗读,所以不要使用省略号 —— 语音引擎不知道怎么读它们。"`
- 原因:模型能从解释中泛化到边界情况,只给规则反而僵化。

**B2. 是否过度使用 ALL CAPS MUST / NEVER?**
- Claude 4.5/4.6/4.7 已经对系统提示非常敏感,过于激烈的措辞反而会触发"过度遵从",在边缘场景上失灵。
- 倾向:用"自然语气 + 解释 why",而不是堆砌大写禁令。

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
- 4.5/4.6 之后模型已经不会"过度不触发"。
- `"CRITICAL: You MUST use this tool when..."` 这种写法在新模型上反而会过触发。

---

## I. Thinking / 推理 (Thinking & Effort)

**I1. 简单任务是否被赋予了不必要的"think hard"指令?**
- 这会导致 token 浪费和延迟膨胀。

**I2. 复杂任务是否给了适合的思考引导(而非死板的 step-by-step 模板)?**
- 通用引导(`"think thoroughly"`)往往比手写 step-by-step 更好。
- 关键词:Opus 4.5 在 thinking 关闭时对 "think" 一词敏感,可换用 "consider"、"evaluate"、"reason through"。

**I3. 是否要求模型在结束前自检?**
- `"在结束前,用 [test criteria] 验证你的答案。"` 能可靠捕获错误。

---

## J. Agentic 系统(适用时)

**J1. 长任务是否有 state tracking 引导?**
- 是否引导模型用 git / tests.json / progress.txt 保存进度?

**J2. 是否提示模型注意可逆性?**
- 危险操作(`rm -rf`、`force push`、`reset --hard`)是否要求用户确认?

**J3. Subagent 是否被恰当节制?**
- 4.6 倾向过度 spawn,需要明确"什么场景下不要 spawn"。

**J4. 是否引导清理临时文件?**

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

---

## 评分维度速记

每条规则 review 时给出:
- **状态**: ✅ 做得好 / ⚠️ 有改进空间 / ❌ 违反最佳实践 / N/A 不适用
- **证据**: 引用提示词原文片段(最多 100 字)
- **why**: 引用 Rubric 对应条目的原因
- **建议改写**: 给出具体修改后的片段(不要只说"改一下")

---

## 写评审报告的防御性原则

这几条不针对被审查的提示词,而是约束评审者自己,防止"为了证明 rubric 有用而硬找问题":

1. **如果一条规则没有被违反,不要把它放进 finding 列表**。可以在维度得分表里标 ✅ 或 N/A,但不要在"❌ 违反"或"⚠️ 改进空间"段强行编一个低权重问题。
2. **总体评估要与 finding 数量校准**。如果 ❌ 严重违反项 ≤ 1,且 ✅ 项 ≥ 5,「总体评估」一行应当包含正向定性(例如"整体写得不错"、"质量较高,主要可优化点是 X")。
3. **不要把"风格偏好"包装成"违反最佳实践"**。如果一个写法 best-practices.md 没有点名反对,只是你觉得不够好,标 ⚠️,不要标 ❌。
4. **控制组测试**:写完报告后扫一眼 —— 如果换一个写得相对好的提示词来审,这份报告的语气会不会过度负面?如果会,降级 ⚠️/⚠️/❌ 的分布。
