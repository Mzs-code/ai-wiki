---
name: review-by-claude-prompting-best-practices
description: 基于 Claude 官方 prompt engineering 最佳实践文章审查并迭代优化用户的提示词(skills/md/system prompt 等)。当用户说"审查这个提示词/skill"、"基于最佳实践 review 我的 prompt"、"优化这个 SKILL.md"、"看看我这个提示词哪里写得不好"、"按 Claude best practices 改我的 prompt"、"review my prompt"、"audit this skill"、"check this prompt against best practices" 等任何涉及提示词质量审查、改进、对照官方规范评估的场景时,务必使用本 skill。即使用户没明说"最佳实践",只要是请求评估或优化已有的提示词/skill/md 文件,也应触发本 skill —— 它会按 Claude 官方文章逐项打分,生成新版副本,并通过双 agent 并发实测对比新老版本的实际效果。
---

# review-by-claude-prompting-best-practices

按 Claude 官方 [prompt engineering 最佳实践](references/best-practices.md) 对用户提供的提示词(skill / md / system prompt / 任何文本形式的 prompt)做一次结构化审查,生成改进版,并通过并发实测验证改动确实有效。

## 何时触发

- 用户给出一段提示词或一个文件路径,请求"审查"、"评估"、"优化"、"review"、"改进"
- 用户说"按最佳实践 check 一下"、"看看哪里违反规范"、"哪里写得不好"
- 用户对自己写的 SKILL.md / system prompt / agent 指令不满意,想知道怎么改
- 用户问"这个 prompt 还能怎么优化"

只要场景是「评估或改进一段已有的提示词」,就触发本 skill。

## 工作流总览

本 skill 是一个 7 阶段流程,分三大段。**每一阶段结束都要明确告知用户当前进度,并在关键节点等待用户确认。**

| 阶段 | 步骤 | 产物 |
|---|---|---|
| A. 审查 | 1-3 | 评审报告 + 等待用户反馈 |
| B. 修订 | 4 | `.v2` 副本 |
| C. 实测 | 5-6 | 双 agent 对比报告 + 二次修订 |
| D. 交付 | 7 | 最终版本(`.v3` 或更高) |

---

## 阶段 A:审查 (步骤 1-3)

### 步骤 1:收集输入并校验缓存

1. **范围甄别**(先过滤非 prompt 文件,避免对人类文档跑 rubric 浪费 token)。列出待审文件,只对**作为模型上下文加载的指令文件**继续:

   - **是 prompt**:`CLAUDE.md` / `AGENTS.md` / `SKILL.md` / `.cursor/rules/*` / `*.prompt.md` / skill 内被引用的 `references/*` / agent 指令 / system prompt 类文件
   - **非 prompt**(跳过):`README.md` / `CHANGELOG.md` / `API.md` / 用户文档 / 设计稿 —— rubric 维度对它们大量 N/A,徒劳
   - **视情况**:`CONTRIBUTING.md` / 流程手册 —— 若被 prompt 文件显式引用为流程入口(被 CLAUDE.md 说「见 X.md」),视为间接 prompt;否则按人类文档跳过
   - 用户清单若混合,告诉用户「审查 N 个,跳过 M 个非 prompt」后继续;不确定时询问用户

2. **确认输入**。用户可能给出:
   - 文件路径(`.md` / `SKILL.md` / `.txt`):用 Read 读取
   - 直接粘贴的提示词文本:直接使用
   - 整个 skill 目录:
     1. 用 Read 读 `SKILL.md`
     2. 在 `SKILL.md` 中 grep 路径引用(`references/`、`scripts/`、`assets/`)
     3. 对每个被引用的文件用 Read 读全文(通常是 rubric / template 类小文件)
     4. 跳过未被引用的辅助文件(`evals/`、log、benchmark 等)

   如果输入不清晰(比如只说"审查我的 skill"但没给路径),直接询问用户:"请提供文件路径或粘贴提示词内容。"

3. **校验最佳实践缓存**。运行 `scripts/check_cache_age.sh`(路径相对于本 skill 根目录,即 SKILL.md 所在目录):
   - `STATUS=fresh`:直接进入步骤 2,使用本地 `references/best-practices.md`
   - `STATUS=stale`:告知用户"缓存已超过 30 天",询问是否要联网刷新。如果用户同意,用 WebFetch 重新拉取 `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices`,覆盖 `references/best-practices.md`,并把首部的 `last_fetched` 改成今天的日期(`date +%Y-%m-%d`)
   - `STATUS=missing`:直接 WebFetch 拉取并保存

   *为什么要这么做:文章会随新模型发布更新。30 天的 TTL 既不会每次重拉浪费 token,又能在重要更新出来时不会拿过期规则去审查。*

### 步骤 2:逐项审查

1. **加载评审 rubric**。读取 `references/rubric.md`(已根据 best-practices.md 浓缩成可执行清单,有 A-K 共 11 个维度)。

2. **逐条对照,记录证据**。对每个维度的每条规则,产出 4 个字段:
   - **状态**: ✅ 做得好 / ⚠️ 有改进空间 / ❌ 违反最佳实践 / N/A 不适用
   - **证据**: 引用提示词原文片段(用 ``引号或代码块`` 包裹,最多 100 字)
   - **why**: 引用 rubric / best-practices.md 对应条目说明原因
   - **建议改写**: 给出具体修改后的片段(可直接 paste 回原 prompt 的文本),而非"改一下"这种空话。

3. **跨条目归纳整体观察**。审查完单条后,再总结 3-5 条整体性观察,例如:
   - "整篇大量使用 ALL CAPS MUST/NEVER,在 Opus 4.5+ 上会过触发"
   - "缺少示例,而任务对输出格式高度敏感"
   - "长文档放在 query 之后,会损失约 30% 回答质量"

4. **兜底 pattern 扫描**(防漏报)。在维度对照之外,对被审查的 prompt 全文跑这几个 grep 作为机械快筛 —— 参考 rubric.md K 表的"快筛信号"列。

   **关键:用 `-o ... | wc -l` 词级计数,不用 `-c` 行计数** —— 因为单行长 prompt(很多 system prompt 都是单行)用行计数会把"一行内出现 5 次 MUST"算成 1,假阴性。

   ```bash
   FILE=<被审查文件路径>
   FILE_BYTES=$(wc -c < "$FILE" | tr -d ' ')

   N_NEG=$(grep -oiE '不要|不能|绝不|不得|不得不|don'\''t|do not|never' "$FILE" | wc -l | tr -d ' ')
   N_CAPS=$(grep -oE 'MUST|NEVER|CRITICAL|ALWAYS|REQUIRED' "$FILE" | wc -l | tr -d ' ')
   N_TMP=$(grep -o '/tmp/' "$FILE" | wc -l | tr -d ' ')
   N_RM=$(grep -oE 'rm |rm -' "$FILE" | wc -l | tr -d ' ')
   N_FUZZ=$(grep -oiE '扫描|处理|分析|检查' "$FILE" | wc -l | tr -d ' ')
   N_OVER=$(grep -oiE '详尽|exhaustive|comprehensive|as much as possible|thoroughly|ALWAYS .{0,20}(be|do|use)' "$FILE" | wc -l | tr -d ' ')

   echo "文件长度:    $FILE_BYTES 字节"
   echo "否定句计数:  $N_NEG"
   echo "高压大写计数: $N_CAPS"
   echo "tmp 引用:    $N_TMP"
   echo "tmp 清理:    $N_RM"
   echo "模糊动词:    $N_FUZZ"
   echo "过度全面:    $N_OVER"
   ```

   **判定阈值**(参考,不是死规则):
   - 否定句 ≥ 3 → E1 严重,加 ❌
   - 高压大写 ≥ 5 → B2 严重,加 ❌
   - tmp 引用 > 0 且 tmp 清理 = 0 → J4 漏清理,加 ⚠️
   - 模糊动词命中 → 看后续 50 字内是否有具体动作,无则 A3 ⚠️
   - 过度全面命中 → K 反模式,加 ⚠️
   - **文件长度 < 500 字节 且 上述信号全部 = 0** → 不是"写得好",而是"内容过稀"(rubric K 表「内容过稀」行)→ 加 ❌,并以 rubric A-F 维度逐项要求补章节

   **跨文档 drift 检测**(仅当待审 ≥ 2 个互相引用的 prompt 文件时跑;最有价值的发现往往来自这里):

   ```bash
   # 1. 结构性重复:同一标题在单文件内出现多次(常因 Edit 时未替换原标题导致)
   for FILE in "$@"; do
     dup=$(grep -nE "^##+ " "$FILE" | awk -F': ' '{print $2}' | sort | uniq -d)
     [[ -n "$dup" ]] && echo "[$FILE] 重复标题: $dup"
   done

   # 2. 跨文件描述不一致:同一主题在多份中给的步骤数 / 清单长度不同
   #    人工对比:若 CLAUDE.md 说「3 步」、CONTRIBUTING.md 同主题说「12 步」→ drift
   #    通常出现在「概要 README + 详细 playbook」两文档之间,容易因后者升级而前者未跟
   ```

   **判定**:
   - 结构性重复 ≥ 1 → ❌(K 表新增「结构性重复」)
   - 描述不一致 / 引用 anchor 失效 → ⚠️,建议「指针化」(把概要 README 中重复的内容改为单一 source of truth 链接)

   *为什么要做这步:维度对照靠"记住所有规则",容易漏。grep 是机械、可重复的兜底 —— 即便审查者一时没想到 E1,grep 也会把否定句数量摆在面前。跨文档 drift 尤其难靠单文件 rubric 发现,机械步是兜底。这步本身不直接产 finding,而是作为 hint 触发评审者回到 rubric 对应条目核实。*

### 步骤 3:输出评审报告并等待反馈

按 **下方模板** 输出报告。报告写完后明确告诉用户:**"以上是基于 Claude 官方最佳实践的审查结果。请给出你的反馈意见 —— 哪些建议你认同?哪些不认同?是否有补充需求?我会基于你的意见生成 `.v2` 副本。"** 然后停止,等待用户输入。

#### 评审报告模板

```markdown
# 提示词审查报告

**审查对象**: `<文件路径或简短描述>`
**审查依据**: Claude Prompting Best Practices (last_fetched: <YYYY-MM-DD>)
**总体评估**: <一句话:这个提示词的主要优势 + 主要短板>

---

## 📊 维度得分

| 维度 | 状态 | 核心问题 |
|---|---|---|
| A. 清晰具体 | ✅/⚠️/❌ | ... |
| B. 解释 Why | ✅/⚠️/❌ | ... |
| C. 示例 | ✅/⚠️/❌ | ... |
| D. XML 结构 | ✅/⚠️/❌ | ... |
| E. 输出格式控制 | ✅/⚠️/❌ | ... |
| F. 角色设定 | ✅/⚠️/❌ | ... |
| G. 长上下文 | ✅/⚠️/❌/N/A | ... |
| H. 工具使用 | ✅/⚠️/❌/N/A | ... |
| I. Thinking | ✅/⚠️/❌/N/A | ... |
| J. Agentic | ✅/⚠️/❌/N/A | ... |
| K. 反模式 | ✅/⚠️/❌ | ... |

---

## ✅ 做得好的地方

1. **<点 1 标题>**
   - 证据:`<引用片段>`
   - why:<为什么这是好的>

(列 3-5 条)

---

## ❌ 违反最佳实践

1. **<问题 1 标题>**
   - 证据:`<引用片段>`
   - 违反:<对应 rubric 条目>
   - why:<根本原因 / 引官方文章>
   - 建议改写:
     ```
     <可直接替换的新文本>
     ```

(按严重度排序,通常 3-7 条)

---

## ⚠️ 有改进空间

(同上格式,列出 ❌ 之外的次要问题)

---

## 🔭 整体观察

1. <跨条目的归纳观察 1>
2. <...>

---

## 🎯 优先级建议

如果只能改 3 处,建议先改:
1. <最高 ROI 修改>
2. <...>
3. <...>
```

---

## 阶段 B:修订 (步骤 4)

### 步骤 4:基于用户反馈生成 `.v2` 副本

1. **吸收用户反馈**。用户可能:
   - 全盘接受建议 → 按报告全部修改
   - 部分否决 → 跳过否决项,只改其余
   - 补充新需求 → 在原报告之外再加修改
   - 完全不同意某条 → 直接遵从用户,**用户的判断高于 rubric**

2. **确定副本路径与命名**。原则:**保留原文件,在同目录创建副本**。
   - 单文件: `foo.md` → `foo.v2.md`
   - 已有 v2:`foo.v2.md` → `foo.v3.md`(以此类推)
   - SKILL 目录:复制整个目录 `my-skill/` → `my-skill.v2/`,只改其中 `SKILL.md` 及相关文件
   - 如果检测到当前不在 git 仓库,且用户没指定路径,默认就用这个 `.vN` 后缀方案
   - 如果用户在 git 仓库 **并明确要求** 原地修改,则原地改并提示"修改未提交,可用 `git diff` 查看"

3. **应用修改**。用 Edit 工具改 `.v2` 副本(原文件保持不变)。改完后:
   - 用 Read 工具读一下 `.v2`,简短列出本次实际修改的要点(3-7 条)
   - 告诉用户副本路径

4. **进入实测前的二次确认**。说:**"`.v2` 已生成在 `<path>`。接下来我会启动 2 个并发 agent 用真实任务对比新老版本的实际效果。这一步会消耗 token 但能验证改动是否真的有改善 —— 是否继续?"** 等用户确认后再进入步骤 5。

   *为什么要二次确认:并发跑两个 agent 不便宜。如果用户只是想要 review 报告 + 改写建议,他可能在 v2 这步就够了。*

---

## 阶段 C:实测 (步骤 5-6)

### 步骤 5:并发双 agent 实测

1. **生成测评任务**。基于待测提示词的用途,设计 1-3 个真实任务场景。任务设计原则:
   - 任务必须真的"调用"这段提示词的能力(不是泛泛问问)
   - 任务应触及该提示词最容易出问题的地方(从步骤 2 的 ❌/⚠️ 推断)
   - 任务的输入(用户消息)对两个 agent 完全一致

   把任务文本写到 `/tmp/<skill-name>-eval-tasks.md`,展示给用户简短确认("准备用这 N 个任务测评,OK?")。

2. **同一回合内并发启动两个 Agent**(用单条消息发多个 Agent tool calls,这是并发的关键):

   **Agent A — 老版本**
   ```
   你是测评 agent A。你将使用 **下面这段提示词** 完成给定任务。
   
   <prompt_under_test>
   <原版提示词全文>
   </prompt_under_test>
   
   <tasks>
   <任务 1>
   <任务 2>
   ...
   </tasks>
   
   按顺序完成每个任务,把输出保存到 /tmp/<skill-name>-eval/old/task-<N>.md。
   完成后,在 /tmp/<skill-name>-eval/old/notes.md 中记录:
   - 你在执行过程中觉得这段提示词哪里清晰、哪里模糊
   - 你需要"猜"的地方
   - 你被迫做出的任何取舍
   ```

   **Agent B — 新版本** (同上,但喂 `.v2` 内容,输出到 `/tmp/<skill-name>-eval/new/`)

   关键:这两个 Agent 必须在 **同一个 assistant 回合的同一条消息中** 被启动,这样它们才会真正并发。分成两条消息发会变成串行,失去同时对比的意义。

3. **等两个 agent 都返回后**,读取两边的 outputs 和 notes。

### 步骤 6:基于实测做二次优化

1. **对比维度**(逐任务):
   - 输出质量:哪边更准确、更对齐用户意图、更完整?
   - 格式合规:哪边输出格式更符合任务要求?
   - 推理清晰度:哪边过程更可读、更少猜测?
   - 效率:哪边更简洁、token 更省(估算即可)?
   - Agent notes 暴露的"模糊点":新版是否真的消除了老版的歧义?

2. **产出对比小结**,大致结构:
   ```markdown
   ## 实测对比
   ### 任务 1: <名字>
   - 老版:<3 句评价 + 关键证据片段>
   - 新版:<3 句评价 + 关键证据片段>
   - 结论:新版 优于/劣于/相当 老版,原因:<...>
   
   ### 任务 2: ...
   
   ## Agent notes 暴露的洞察
   - <来自 agent A/B 自述的关键观察>
   
   ## 二次优化方向
   - <基于实测发现的额外修改 1>
   - <...>
   ```

3. **生成 `.v3` 副本**(基于 `.v2` 再改一次)。如果新版在所有任务上都更好且 agent notes 没暴露新问题,可以告诉用户"`.v2` 已经足够,不需要 v3"。如果发现新问题,生成 `.v3`,只针对实测发现的具体问题做修补(整轮 rubric 已经在 v2 应用过,无需重做)。

---

## 阶段 D:交付 (步骤 7)

### 步骤 7:总结与交付

输出最终交付清单:

```markdown
# 优化交付

**原文件**: `<原路径>` (未修改)
**最终版本**: `<.v3 或 .v2 路径>`
**关键改动概要**: (3-5 句)

## 改动历程
- v1 → v2: <核心改动,基于 rubric>
- v2 → v3: <核心改动,基于实测> (如有)

## 实测结论
<新版相比老版在 N 个任务中:更优 X / 持平 Y / 更差 Z>

## 建议下一步
- 如果该提示词被实际系统使用,建议在真实流量上灰度对比
- 如果有更多场景需要测试,可以追加任务再跑一轮
```

**清理中间产物**:删除步骤 5 产生的临时文件:
```bash
rm -rf /tmp/<skill-name>-eval-tasks.md /tmp/<skill-name>-eval/
```
如果实测产物可能对用户有价值,先问 *"实测中间产物保留还是清理?"* 再决定。默认行为是清理,避免 `/tmp/` 累积残留。

最后简短问一句:"还有其他想测的场景吗?如果没有,本次审查到此结束。"

---

## 重要原则 (Anti-patterns to avoid in this skill)

1. **改动写到 `.vN` 副本,原文件保持不变**。这是用户唯一的回退路径。除非用户在 git 仓库内明确同意原地修改,否则始终走副本方案。

2. **用户反馈高于 rubric**。Rubric 是参考,不是法律。如果用户说"我故意用 ALL CAPS 因为下游模型旧",就按用户的来。

3. **默认走 rubric.md 路线,best-practices.md 按需 spot-read**。
   rubric.md 是 best-practices.md 的 11 维浓缩(约 180 行 vs 900 行,省约 40% token)。审查的 90% 场景在 rubric 上完成。

   **触发 spot-read best-practices.md 的具体情况**:
   - rubric 某条找到了证据但你不确定原文严重程度 → 打开对应章节确认
   - 被审查的提示词触及 rubric 未覆盖的领域(如 computer use、vision、特殊 thinking 配置)→ 打开 best-practices.md 相关章节
   - rubric 与你的判断冲突 → 以 best-practices.md 为准

   **Why**:三层 progressive disclosure 是官方 skill 设计原则。实测仅用 rubric 即可在常见反模式上拿满分;全文加载约多用 30-50% token,且容易让模型过度索引到无关章节,无可见收益。

4. **并发是关键**。步骤 5 中两个 agent 必须在同一条消息中启动 —— 串行启动既慢、又破坏了"同时对比"的语义。

5. **执行严格限定在 7 步流程内**。流程外的动作(把审查结果应用到用户的其他文件、commit 改动、push、新建分支等)先问用户。

   **Why**:超出流程的动作通常涉及共享状态或难撤销,值得一次明确同意。

---

## 文件结构

```
review-by-claude-prompting-best-practices/
├── SKILL.md                          (本文件)
├── references/
│   ├── best-practices.md             (官方文章本地缓存,~900 行)
│   └── rubric.md                     (浓缩评审清单,11 维度)
├── scripts/
│   └── check_cache_age.sh            (缓存年龄检查)
```
