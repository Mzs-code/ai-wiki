# workflow-templates/ 子目录索引

> 本目录为 `../SKILL.md` 的配套模板套件。新项目按 SKILL.md 走 7 步流程时,各步会引用本目录的对应模板。
>
> **数字阈值**:见 [`../SKILL.md`](../SKILL.md) "数字阈值单一来源" 块。

---

## 模板清单

| 模板 | 用途 | 何时用 | 行数 |
|---|---|---|---|
| `stage-template.md` | IMPLEMENTATION 单阶段模板 + 验收门双模板 | SKILL.md 步骤 4 拆 IMPLEMENTATION + 步骤 5 每阶段验收 | ~200 |
| `progress-template.md` | PROGRESS.md 模板(跨会话唤醒锚点)| SKILL.md 步骤 5 实施期 + 跨会话续做 + 多 AI 接手 | ~250 |
| `review-agent-prompt.md` | 独立 review agent 6 槽位 **XML** prompt | 所有 L1 / L2 agent 钩子启动前必读 | ~300 |
| `review-workflow-template.md` | **Workflow 化**的 L1/L2 review fan-out(可运行脚本 + schema 强制 finding)| **默认 subagent**;仅命中可复现 / 宽 fan-out / 硬 schema 之一 **且模型 ≥ Opus 4.8** 时升级(决策门见模板 §0)| ~360 |
| `seven-dim-review.md` | 七维 review 完整提示词 | SKILL.md 步骤 3 多轮 review + 每阶段末 L1 七维触发 | ~470 |
| `review-output-template.md` | finding/filtering 两阶段 + P0/P1/P2 分级 + 修订后扫描 6 步 + revision-checklist + 局部 review 范围 | review agent 输出格式参照 + 修订后必跑 | ~330 |
| `agents-md-skeleton.md` | AGENTS.md 五段式骨架 + docs/ 矩阵 + reviewRule 增量 vs 重写决策 | SKILL.md 步骤 7 文档体系生成 | ~290 |

---

## 首次只读 3 个速通路径(认知减负)

新项目首次实施者**先掌握以下 3 个模板**(对应 SKILL.md §0.1 Core 5 中的 C3/C4/C5),其余按需展开:

1. **`stage-template.md`** — 知道每阶段长什么样、验收门怎么填(对应 Core C3)
2. **`progress-template.md`** — 知道跨会话唤醒怎么做、PROGRESS.md 长什么样(对应 Core C4)
3. **`review-agent-prompt.md`** — 知道启动 agent 时 XML 6 槽位怎么填(对应 Core C5)

读完这 3 个 + SKILL.md §0 / §1 / §2 即可开工;其余模板**在用到时**再读。

特别地,**`seven-dim-review.md` 默认只读 `<core_summary>` 段**(≤ 100 行);具体 Pass 触发时再 Read 对应 `<pass_N_*>` 章节。

---

## 模板调用图(SKILL.md / steps/ ↔ 模板)

```
SKILL.md(总览 + 通用纪律)
│
├─ §0.1 概念分层 + 首读路径
│   ├─ Core 5(必读)/ Extended 13(按需)
│   └─ 入口决策树 4 种(A 新建 / B 维护 / C V2 / D PoC)
│
├─ §0.4 为什么用多 subagent(给 4.7+ 的解释)
│
├─ §2 通用纪律 9 条 ←→ stage-template.md §0.2
│
├─ §3 七步详述跳转索引 → steps/ 子目录
│
├─ §4 模板与外部资源(导航 6 个模板)
│
└─ §5 退出条件 + 多 AI 接手 + 长期续做
    └─ 接手分支 ←→ progress-template.md §5 + review-agent-prompt.md §3.7(接手 sanity-scan)


WORKFLOW/steps/(7 个步骤详述)
│
├─ step1-demo-doc.md(步骤 1 demo 文档化)
│   └─ Agent 钩子 L1/L2 ←→ review-agent-prompt.md(反向重建)
│
├─ step2-plan-design.md(步骤 2 plan 平行分解)
│   └─ Agent 钩子 ←→ review-agent-prompt.md(覆盖范围反查)
│
├─ step3-review.md(步骤 3 多轮 review)
│   ├─ 七维 pass ←→ seven-dim-review.md <core_summary>
│   ├─ 输出格式 ←→ review-output-template.md <finding_phase_format> + <filtering_phase_format>
│   ├─ 修订后强制扫描 6 步 ←→ review-output-template.md <revision_scan_6_steps>
│   ├─ revision-checklist ←→ review-output-template.md §5
│   ├─ 局部 review(路线级)←→ review-output-template.md §6
│   ├─ 回环退出 ≤3 轮 + L0 选项 A/B/C ←→ review-output-template.md §3.5
│   └─ Agent 钩子 ←→ review-agent-prompt.md(七维 / sanity-scan)
│
├─ step4-impl-split.md(步骤 4 拆 IMPLEMENTATION)
│   ├─ 单阶段结构 ←→ stage-template.md §1
│   ├─ 验收门双模板 ←→ stage-template.md §0.3
│   ├─ 阶段编号约定 ←→ stage-template.md §1.7
│   └─ Agent 钩子 ←→ review-agent-prompt.md(实施者反向)
│
├─ step5-execution.md(步骤 5 分阶段实施)
│   ├─ commit 拦截 ←→ stage-template.md §1.5 + SKILL.md §0.3 <commit_mechanism>
│   ├─ NOTES → plan + IMPLEMENTATION 反向同步 ←→ stage-template.md §2
│   ├─ 三轨制 + 四象限 ←→ stage-template.md §1.6
│   ├─ PROGRESS 同步 ←→ progress-template.md(全文)
│   └─ Agent 钩子 ←→ review-agent-prompt.md(按阶段类型选)
│
├─ step6-demo-diff.md(步骤 6 demo 对比调优)
│   └─ Agent 钩子 ←→ review-agent-prompt.md(陌生用户视角)
│
└─ step7-doc-system.md(步骤 7 文档体系生成)
    ├─ AGENTS.md / CLAUDE.md 命名 ←→ agents-md-skeleton.md §0
    ├─ 五段式 ←→ agents-md-skeleton.md §1
    ├─ 顶层 vs 模块级 ←→ agents-md-skeleton.md §2
    ├─ docs/ 矩阵 + reviewRule 增量 vs 重写 ←→ agents-md-skeleton.md §3
    ├─ 资产穷举索引 ←→ agents-md-skeleton.md §4
    ├─ 多模块 PROGRESS 分层 ←→ agents-md-skeleton.md §6
    └─ Agent 钩子 ←→ review-agent-prompt.md(文档可索引性 + 反例溯源)
```

---

## 模板间引用关系(避免重复 / 防双写漂移)

- **stage-template.md** 引用 **review-output-template.md** 验收门 / review-agent-prompt 启动 agent
- **review-output-template.md** 引用 **seven-dim-review.md** 反模式 / Pass 间交叉
- **progress-template.md** 引用 **review-agent-prompt.md** 接手分支 agent
- **agents-md-skeleton.md** 引用 **review-output-template.md** reviewRule 输出格式

**双写漂移防护**:同一概念只在一个模板**主定义**,其他模板用 "详见 X §Y" 指针引用。修订主定义时,grep 所有指针逐个核对。

**数字阈值单一来源**:所有阈值集中于 SKILL.md "数字阈值单一来源" 块,其他文件用 `<占位符>` 引用,不重复声明。修订阈值时只改 SKILL.md 一处。
