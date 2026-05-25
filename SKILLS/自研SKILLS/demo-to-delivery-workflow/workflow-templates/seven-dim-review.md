# 七维 review 方法论(通用模板)

> **本文件定位**:七维 review 的**入口 + 摘要 + 跳转表**。每个 Pass 的强约束细节、修订扫描清单、反模式、交叉提示均在 [`seven-dim/`](seven-dim/) 子目录,L1 review subagent 默认只 Read 本文件 `<core_summary>`,跑具体 Pass 时再 Read 对应子文件。渐进披露设计让单 Pass 加载 ≤ 80 行,避免一次性吞下全 7 Pass 的强约束(详见 [`../SKILL.md`](../SKILL.md) §0.4 上下文预算管理)。

---

<template_reuse_guide audience="human">

## 模板复用指引(给复用本模板到新项目的人)

> 本段是给**人类用户**(把本套工作流复用到新项目的工程师)看的,不是给模型的 prompt 指令。模型不应当从本段推断"必须使用 React Query / Pydantic"等技术栈约束。

- **保留术语白名单**(技术栈关键词,下次新项目仍可能用同样栈,保留即可):React Query / Pydantic / SQLAlchemy / FastAPI / Zustand / shadcn / Tailwind / TypeScript / Python / SQL 等
- **应泛化术语表**(本项目业务专有词,新项目使用时按你的领域替换):
  - `closure_*` / `closure_record` / `closure_questions` → 你的业务关闭/确认字段
  - `Phase` / `phase 状态机` → 你的业务状态机(此概念普适,只是名字变)
  - `IBOY` → 你的业务实例标识
  - `record` / `record_service` / `record_guid` → 你的业务实体名
  - `record_kind_version` 等具体唯一约束名 → 你的实际约束名
  - 具体文件路径 `app/services/record_service.py` 等 → 加 "(本项目示例)" 或替换为你的项目路径
- **不允许内容裁剪**:七维方法论是整体,任一 pass 不可省;Pass 间交叉提示与反模式清单也不能删 — 复用到新项目时若发现不适用,改写为"该项目空 finding"或在 PROGRESS.md 顶部声明"降级 skip",但不要直接删除子文件

</template_reuse_guide>

---

<core_summary>

## 七维 review 核心摘要(默认只读本段)

> **使用约定**:
> - L1 review subagent 默认只 Read 本 `<core_summary>` 段,跑具体 Pass 时再 Read [`seven-dim/pass-N-*.md`](seven-dim/) 对应子文件
> - finding 阶段(coverage 优先)的输出格式见 [`review-output-template.md`](review-output-template.md) `<finding_phase_format>`
> - 七维方法论作为 reviewer 视角的工具箱,**不所有项目都需要全 7 pass**:小项目降级跑 1+2+3+7 即可(详见 [`review-agent-prompt.md`](review-agent-prompt.md) §3.1 edge case)

### 7 个 Pass 一句话

| Pass | 名称 | 核心动作 | 子文件(详读) |
|---|---|---|---|
| 1 | 链路追踪 | 顺声明 → 实现 → 调用 → 异常路径,任何链路断裂即 finding | [`seven-dim/pass-1-link-trace.md`](seven-dim/pass-1-link-trace.md) |
| 2 | Self-claim 验证 | "X 单一来源" / "对齐 schema" 等声明,grep 反证 | [`seven-dim/pass-2-self-claim.md`](seven-dim/pass-2-self-claim.md) |
| 3 | 实施者反向 | 真敲 30-80 行模拟代码,看 plan 假设是否被满足;async/await + import + 派生字段 | [`seven-dim/pass-3-implementer-reverse.md`](seven-dim/pass-3-implementer-reverse.md) |
| 4 | 框架运行时语义 | 脑中 simulate SQLAlchemy / FastAPI / asyncio / React Query / Pydantic 真实行为 | [`seven-dim/pass-4-framework-runtime.md`](seven-dim/pass-4-framework-runtime.md) |
| 5 | 覆盖范围反向 | 每个机制问"它不覆盖哪些场景?后果?" | [`seven-dim/pass-5-coverage-reverse.md`](seven-dim/pass-5-coverage-reverse.md) |
| 6 | 跨层对照 | UX ↔ API ↔ 数据模型 ↔ service 实现 间的字段集 / 命名 / 时序一致性 | [`seven-dim/pass-6-cross-layer.md`](seven-dim/pass-6-cross-layer.md) |
| 7 | 大改后 sanity scan | 章节漂移 / import 漂移 / 旧命名残留 / 跨文件引用 | [`seven-dim/pass-7-sanity-scan.md`](seven-dim/pass-7-sanity-scan.md) |

### 跑七维 review 的高频指引(reviewer 启动前默读)

按"做什么"组织,而非"不做什么":

- **每个声明都验到端**:Pass 1 不要把章节当独立段落读完就过,顺链路追到代码落地
- **Self-claim 必 grep 反证**:Pass 2 "X 单一来源 / 字段集对齐"等声明,grep / 列举 / 字段集对比三选一
- **真敲代码,不口算**:Pass 3 finding 必须带 `<implementer_reverse_code>` 字段(30-80 行模拟代码);此字段是机械校验项,缺失视为伪 finding
- **大改后必跑 sanity scan**:修订完成后立即跑 [`seven-dim/revision-scan-checklist.md`](seven-dim/revision-scan-checklist.md) 6 步,显式列出"6 步逐项做了"
- **用 confidence/severity 替代模糊语**:不写"建议加强 / 待完善",用 [`review-output-template.md`](review-output-template.md) `<finding_phase_format>` 的 `<original_quote>` + `<observation>` + `<impact>` 落地

详细反模式清单(`<pitfall>` / `<correct>` 配对块)见 [`seven-dim/antipatterns.md`](seven-dim/antipatterns.md)。

### Pass 间交叉提示(最常用 4 条)

完整交叉提示见 [`seven-dim/cross-pass-tips.md`](seven-dim/cross-pass-tips.md);**最常用 4 条**:

1. **async 函数调用缺 await** → Pass 3 + 4 + 7 三重(grep `async def` 反查 caller)
2. **schema 字段 ORM 不存在 / response_model 反射 AttributeError** → Pass 3 真敲 endpoint handler 反射代码 + Pass 6 跨层
3. **修订引入 import 漂移** → Pass 3 import 扫描 + Pass 7 修订重跑(每改一段示例代码立刻反查 import 段)
4. **React Query queryKey 漏参数** → Pass 4 + Pass 3(grep queryFn params vs queryKey 字段集)

### 区分两类 finding

- `<contradiction>` plan 自相矛盾 — Phase B 大概率判 P0/P1
- `<design_tradeoff>` plan 设计选择存疑 — Phase B 标 trade-off 等用户决定

### 默认跑七维 的输出节制

- Phase A finding:coverage 优先,low-confidence 也报(标 `confidence="low"`),不要自我过滤
- 跳过的 Pass 显式声明 `<pass_skipped reason="...">`,不省略

</core_summary>

---

# 触发指令:用七维方法论对 plan / 设计文档做深度 review

执行下面 7 个独立 pass,每个 pass 各自产出 finding 清单(`<finding_phase_format>` 见 [`review-output-template.md`](review-output-template.md)),最后由 Phase B 合并按 P0/P1/P2 分级。

**Reviewer 默认跑全 7 pass**;小项目降级 / 局部 review 时按 [`review-output-template.md`](review-output-template.md) §6 选受影响 pass 跑;跳过的 Pass 显式声明,不静默省略。

| Pass | 详读子文件(强约束 + 反例 + 验证手法) |
|---|---|
| Pass 1 链路追踪 | [`seven-dim/pass-1-link-trace.md`](seven-dim/pass-1-link-trace.md) |
| Pass 2 Self-claim 验证 | [`seven-dim/pass-2-self-claim.md`](seven-dim/pass-2-self-claim.md) |
| Pass 3 实施者反向 | [`seven-dim/pass-3-implementer-reverse.md`](seven-dim/pass-3-implementer-reverse.md) |
| Pass 4 框架运行时语义 | [`seven-dim/pass-4-framework-runtime.md`](seven-dim/pass-4-framework-runtime.md) |
| Pass 5 覆盖范围反向 | [`seven-dim/pass-5-coverage-reverse.md`](seven-dim/pass-5-coverage-reverse.md) |
| Pass 6 跨层对照 | [`seven-dim/pass-6-cross-layer.md`](seven-dim/pass-6-cross-layer.md) |
| Pass 7 大改后 sanity scan | [`seven-dim/pass-7-sanity-scan.md`](seven-dim/pass-7-sanity-scan.md) |

---

## 修订后强制扫描清单

每次完成 plan 修订后,**立即**跑 [`seven-dim/revision-scan-checklist.md`](seven-dim/revision-scan-checklist.md) 的 6 步,并在交付时**显式列出**"6 步逐项做了"或"哪步跳过 + 为什么"。

**强约束**:这个清单**不允许跳过**。过去 N 轮实证数据:几乎每一轮都有 1-2 项是修订引入的(import 漂移 / 同段对齐 / 旧命名残留 / 描述与代码不一致)。

---

## 输出约束与反模式

详见 [`seven-dim/antipatterns.md`](seven-dim/antipatterns.md):
- **输出约束**:三档分级 P0/P1/P2 / 每条 issue 必含具体行号 + 修法 + 影响面 / 区分 contradiction vs design_tradeoff
- **反模式清单**:30+ 条 `<pitfall>` / `<correct>` 配对块,覆盖方法论级反模式 + P0/P1 类反模式

---

## Pass 间交叉提示

详见 [`seven-dim/cross-pass-tips.md`](seven-dim/cross-pass-tips.md):按风险类型 → 最有效 Pass → 单 Pass 不够时的协同手法,完整经验沉淀表。
