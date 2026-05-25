# 步骤 2:Plan 设计(平行分解)

> **配套**:[../SKILL.md](../SKILL.md) 总览 + 通用纪律 · 上一步 → [step1-demo-doc.md](step1-demo-doc.md) · 下一步 → [step3-review.md](step3-review.md)
>
> **入口适配**:A(新建)/ B(维护性,plan 简化只覆盖增量维度)/ C(V2 增量,只新维度 + 受影响 V1 维度)必跑;D(PoC)探索模式可省

---

**目标**:按可独立 review 的维度把业务翻译为 plan;字段 / API / 类型在唯一源文件集中声明。

**产物**:`plans/00-overview.md` + `plans/01-NN-<维度>.md`;首次进入步骤 2 时创建 `plans/archive/` 子目录(供步骤 3 review 沉淀用)。

**验收门类型**:文档型 5 项

**裁剪建议(4 套版本)**:
- **纯前端 SPA**:00 + 组件 + 逻辑 + 测试(4 份)
- **纯后端**:00 + 数据 + 架构 + API + 业务 + 测试(6 份)
- **CLI / Lib**:00 + 数据契约 + 命令契约 + 测试(4 份)
- **Notebook / 数据科学**:00 + 数据集 schema + 分析步骤 + 可视化契约(4 份)
- 以上是参考,新项目可自定义维度(在 PROGRESS.md 顶部标注)

**入口形态适配**:
- **A(新建)**:完整 N 份本项目维度
- **B(维护性)**:从此步开始,plan 简化(只覆盖增量维度)
- **C(V2 增量)**:从此步开始(只新维度 + 受影响 V1 维度)

**反问钩子(开头)— 按必答类别 coverage 组织,每类至少 1 条**:

<asking_examples>

| 类别 | 至少 1 条 yes/no 钩子 |
|---|---|
| **维度覆盖** | demo 涉及哪些维度?列出本项目实际选的 N 份 plan,逐个对照"demo 中哪段触发了此维度" |
| **字段单一来源** | 字段 / API 是否只在一份 plan 集中声明?grep 关键字段名,期望只 1 处定义 + N 处引用 |
| **跨 plan 引用形态** | 跨 plan 引用用"位置 + 章节号" vs 重复定义?grep `class X` / `def Y` 反证 |
| **技术栈版本锁** | 版本是否锁主版本号?(防 Tailwind v3 → v4 / React Router v6 → v7 / Zustand v4 → v5 类破坏性更新) |
| **API 集中声明**(全栈/后端项目) | API 路由是否只在 1 份 plan 集中声明?其他 plan 用引用?|

**Good vs Bad**:

✓ "grep -n 'record_status' plans/*.md 期望命中 1 处 type 定义 + N 处引用" — 可 grep + 可计数
✓ "package.json 中 dependencies 是否锁主版本号(`^X.Y.Z` 形式,无 'latest')?" — 可 grep
✗ "看一下字段定义" — 不可答
✗ "技术栈大致没问题" — 不可验证

</asking_examples>

**Agent 钩子(三层)**:

> **通用 agent 规则**:详见 [`../SKILL.md`](../SKILL.md) §0.4 + §2 第 6 条。本文件只列本步骤特有内容。

- **L0 人工**:用户对照 demo 检查 plan 维度划分,确认无缺漏
- **L1**:启动 1 个 Plan agent;prompt 用 [`../workflow-templates/review-agent-prompt.md`](../workflow-templates/review-agent-prompt.md) XML 6 槽位填:
  - `<role>`:覆盖范围反查 — demo 所有功能是否都被某 plan 覆盖
  - `<must_read>`:demo 三件套 + 当前 plan 全部文件
  - `<output_format>`:未覆盖功能清单 + 字段重复定义清单(coverage 优先,带 confidence)
  - `<constraints>`:列出 demo 每个流程节点 → 哪份 plan 覆盖;未覆盖标 finding category="contradiction"
  - `<failure_examples>`:首轮用 `<no_prior_examples/>`;典型(后端项目)— "异步任务链路在 plan 03 提到但 plan 04 状态机没覆盖"
  - `<user_context>`:...
- **L2**:修订后 sanity-scan(跨 plan 字段重复定义 / 章节号断号)

**细节**:每份 plan ≤ 1500 行;字段集中在 1-2 份核心 plan;跨 plan 重复字段定义 标记为 finding(category=contradiction)。

**本项目示例**:`archive/plans/00-overview.md` ~ `07-testing.md`(7 份)
