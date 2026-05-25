# 步骤 7:文档体系生成

> **配套**:[../SKILL.md](../SKILL.md) 总览 + 通用纪律 · 上一步 → [step6-demo-diff.md](step6-demo-diff.md)
>
> **入口适配**:A(新建)必跑;B / C 追加;D(PoC)进工程模式后跑

---

**目标**:产出可读、可维护、可索引的文档体系;**给人(README)vs 给 AI(AGENTS.md / CLAUDE.md)双轨**。

> **项目级指令文件命名约定**:见 [`../workflow-templates/agents-md-skeleton.md`](../workflow-templates/agents-md-skeleton.md) §0。本项目主用 Claude Code,因此 `CLAUDE.md` 是主文件;内容指向 `AGENTS.md`(跳转表)。

**产物结构**:

```
仓库根/
├── README.md           # 给人:总览 + 技术栈表 + 目录结构 + 快速开始
├── AGENTS.md           # 给 AI:纯跳转表(项目速览 + 模块入口)
├── CLAUDE.md           # 给 Claude Code:简短转发到 AGENTS.md(若主用 Claude Code 则反过来)
├── <模块>/
│   ├── README.md       # 给人:模块说明 + 启动 + 部署
│   ├── AGENTS.md       # 给 AI:五段式
│   └── docs/
│       ├── changelog.md     # 日期倒序
│       ├── reviewRule.md    # P0/P1/P2 checklist(从历史 LOG/NOTES/REVIEW 机械抽取)
│       ├── config.md        # 配置字段表
│       ├── releases.md      # 发布记录
│       ├── todo.md          # V2 backlog
│       └── <资产穷举索引>.md # 可选(详见 agents-md-skeleton.md §4)
```

**验收门类型**:文档型 5 项

**AGENTS.md 五段式**(模板见 [`../workflow-templates/agents-md-skeleton.md`](../workflow-templates/agents-md-skeleton.md) §1):
1. 开篇必读(高频流程浓缩,≤ 5 条)
2. §1 功能 ↔ 代码索引表(宽表)
3. §2 各领域编码红线(每条 1-3 行,只说约束)
4. §3 必看 utility 速查(文件 + 一句话)
5. §5 维护契约

**资产穷举索引**(可选,前端复杂项目推荐):
- `zod-fallback.md`(类型兜底)
- `design-tokens.md`(Tailwind token)
- `components-index.md`(组件 props / hooks / data-test)
- `hooks-index.md`(queryKey / endpoint / invalidate)
- **价值**:AI 按"资产名"反查比按"业务功能"快

---

## reviewRule.md 输入来源约束

**新建项目(入口 A)**:
- 从 `archive/plans/LOG.md` + `IMPLEMENTATION-NOTES.md` + `archive/plans/archive/REVIEW-*.md` 机械抽取
- 每条 P0 / P1 grep 反例文件命中 ≥ 1;命中 0 → 移除
- AI 凭训练数据写的通用 best practice(如"所有函数都应有 type hint")若本项目未踩过 → 移除

**维护性项目(入口 B)**:
- reviewRule 追加新条目(基于本次增量的新 LOG/NOTES/REVIEW)
- 不重写已有 P0/P1
- 以日期分段标注(如 `## 2026-05-13 追加 P0(基于 V1.5 增量)`)

**V2 增量(入口 C)**:
- 同 B,reviewRule 追加(以版本/日期分段)
- V1 reviewRule 保留

---

**顶层 vs 模块级分工**:顶层只放跳转表,规则 / 红线全在模块级(避免双写漂移)

**行数预算**:`AGENTS.md` ≤ `agents_md_loc_budget`(默认 300);`reviewRule.md` ≤ `review_rule_loc_budget`(默认 200);超出 → 压缩 §5 grep 清单或下沉

**反问钩子(开头)— 按必答类别 coverage 组织,每类至少 1 条**:

<asking_examples>

| 类别 | 至少 1 条 yes/no 钩子 |
|---|---|
| **模块划分判定** | 项目是否真有"模块级"划分?(单模块项目可省顶层 AGENTS.md)|
| **资产穷举索引必要性** | 需要资产穷举索引吗?(前端 / 类型复杂项目推荐)|
| **reviewRule 反例溯源** | reviewRule 每条 P0 能 grep 到 LOG/NOTES/REVIEW 命中?列出每条来源 |
| **reviewRule 生成方式** | 入口形态决定 reviewRule 是机械抽取(A)还是追加(B/C)|
| **主指令文件命名** | 主用的 AI 工具是 Claude Code / Cursor / Codex?决定主文件是 CLAUDE.md / .cursorrules / AGENTS.md |

**Good vs Bad**:

✓ "AGENTS.md 行数 ≤ 300(`wc -l backend/AGENTS.md` 命中 ≤ 300)?reviewRule.md ≤ 200?" — 可命令
✓ "reviewRule 每条 P0/P1 都能 grep 到 archive/plans/LOG.md 命中?每条标命中文件名:行号?" — 可 grep + 可计数
✗ "AGENTS.md 写得差不多" — 不可验证
✗ "reviewRule 条目合理" — 无具体口令

</asking_examples>

**Agent 钩子(双层 L1 + L0 人工)**:

> **通用 agent 规则**:详见 [`../SKILL.md`](../SKILL.md) §0.4 + §2 第 6 条。本文件只列本步骤特有内容。

- **L0 人工**:用户审阅 AGENTS.md / CLAUDE.md 可索引性(5 个典型查询能否命中)
- **L1 文档可索引性 agent**:启动 1 个 Explore;prompt 用 [`../workflow-templates/review-agent-prompt.md`](../workflow-templates/review-agent-prompt.md) XML 6 槽位填:
  - `<role>`:文档可索引性 — 以"陌生 AI 视角"只读 AGENTS.md / CLAUDE.md 不读代码,反推能否定位所有典型业务功能 / utility / 测试
  - `<must_read>`:AGENTS.md / CLAUDE.md 主文件 + 各 docs/*.md
  - `<output_format>`:5 个典型 query 期望命中段 vs 实际命中段;coverage 优先
  - `<constraints>`:不读实际代码(测可索引性,不测理解力)
  - `<failure_examples>`:首轮 `<no_prior_examples/>`
  - `<user_context>`:...
- **L1 reviewRule 反例溯源 agent**:启动 1 个 Plan;prompt 用 XML 6 槽位填:
  - `<role>`:反例溯源 — 验证 reviewRule 每条 P0/P1 是否能在 LOG/NOTES/REVIEW 找到原始踩坑出处
  - `<must_read>`:`<模块>/docs/reviewRule.md` + `archive/plans/LOG.md` + `IMPLEMENTATION-NOTES.md` + `archive/plans/archive/REVIEW-*.md`
  - `<output_format>`:每条 reviewRule 标 "命中(<反例文件:行>)" 或 "找不到出处 → 待用户决定"
  - `<constraints>`:grep 反例文件命中 ≥ 1;通用 best practice 本项目未踩过的 → 标记移除
  - `<failure_examples>`:首轮 `<no_prior_examples/>`
  - `<user_context>`:...

**本项目示例**:`backend/AGENTS.md` + `frontend/AGENTS.md` + `backend/docs/` + `frontend/docs/` + 资产穷举索引 4 份(`zod-fallback / design-tokens / components-index / hooks-index`)+ 顶层 `CLAUDE.md` 转发 `AGENTS.md`
