# 步骤 4:拆分 IMPLEMENTATION

> **配套**:[../SKILL.md](../SKILL.md) 总览 + 通用纪律 · 上一步 → [step3-review.md](step3-review.md) · 下一步 → [step5-execution.md](step5-execution.md)
>
> **入口适配**:A / B / C 必跑

---

**目标**:把 plan 翻译为"按阶段顺序执行 + 每阶段验收门通过才进下一步"的实施清单。

**产物**:`IMPLEMENTATION-<模块>.md`(每独立模块一份;单模块项目可省"模块"前缀直接 `IMPLEMENTATION.md`)

**验收门类型**:文档型 5 项

**每份结构**(模板见 [`../workflow-templates/stage-template.md`](../workflow-templates/stage-template.md) §0):
- §0.1 阶段全景表(阶段号 / 目标 / 关键交付 / **验收门类型** / 退出门关键口令 / 参考耗时)
- §0.2 通用约束(引 SKILL.md §2 的 9 条)
- §0.3 验收门双模板(代码型 5/6 + 文档型 5)
- §X0 - §XN 每阶段独立章节(标"验收门类型:代码型 / 文档型")

**阶段编号**:
- 多模块用 `<模块前缀>X`(如 `API0` / `UI0` / `CLI0` / `ETL0`)
- 单模块项目可纯数字(`0` / `1` / ...)或保留单字母前缀(`S0` / `M0`)

**验收门双模板**(详见 [`../workflow-templates/stage-template.md`](../workflow-templates/stage-template.md) §0.3):
- **代码型 5/6**:代码到位 / 单测绿 / 集成测/组件测/契约测(按项目类型变体)/ 手工 smoke / grep 防回归 / 跨模块跨进程契约对齐(第 6 项触发条件出现时强制 6/6)
- **文档型 5**:产物文件齐备 / 反向重建测(差异 ≤ N = 节点 × 10% 向上取整,最小 1)/ 5 个典型查询走通 / 链接章节号 grep / 源代码行数偏差 < `loc_drift_threshold`

**反问钩子(开头)— 按必答类别 coverage 组织,每类至少 1 条**:

<asking_examples>

| 类别 | 至少 1 条 yes/no 钩子 |
|---|---|
| **阶段间依赖显式化** | 阶段间是否有隐式依赖未声明?列出每阶段的"前置阶段产出依赖项"(具体到文件 / 函数名) |
| **grep 防回归 5 分钟阈值** | 每阶段的 grep 防回归命令能否 5 分钟内跑完?列命令清单 + 标注预计耗时 |
| **验收门口令具体性** | 每项验收门都有具体口令?(如"我跑了 X / 输出 Y / grep Z 计 0 hit",而非"应该都过了")|
| **阶段编号约定** | 用多模块前缀(API0/UI0)还是单模块纯数字?编号空间不会冲突? |
| **commit 颗粒** | 每阶段 1-3 commit?prefix 与阶段号一致(`feat(S2): ...`)?|

**Good vs Bad**:

✓ "阶段 S2 验收门口令:`pytest tests/unit/test_record_service.py -q` 退出码 0 + `grep -rn 'def insert_history' app/services/` 命中 ≥1" — 可命令 + 可计数
✓ "每个 grep 防回归命令独立耗时 ≤ 60s,5 个共 ≤ 300s?" — 可计时
✗ "阶段产物应该都齐了" — 不可答
✗ "测试基本都过了" — 不可验证

</asking_examples>

**Agent 钩子(三层)**:

> **通用 agent 规则**:详见 [`../SKILL.md`](../SKILL.md) §0.4 + §2 第 6 条。本步骤特有 — Pass 3 finding 必须带 `<implementer_reverse_code>` 字段。

- **L0 人工**:用户检查阶段全景表 + 验收门口令具体性
- **L1**:启动 1 个 Plan agent;prompt 用 [`../workflow-templates/review-agent-prompt.md`](../workflow-templates/review-agent-prompt.md) XML 6 槽位填:
  - `<role>`:实施者反向 — 第 N 阶段开始时第 N-1 阶段产物是否真的够用
  - `<must_read>`:本份 IMPLEMENTATION + 主 plan + demo 三件套
  - `<output_format>`:每阶段前置依赖是否真够用(具体到文件/函数清单);coverage 优先
  - `<constraints>`:真敲 30-80 行模拟代码;不接受"看起来 OK"
  - `<failure_examples>`:首轮 `<no_prior_examples/>`
  - `<user_context>`:...
- **L2**:修订后 sanity-scan(阶段编号 / 章节号 / 引用)

**本项目示例**:`archive/plans/IMPLEMENTATION-backend.md` + `archive/plans/IMPLEMENTATION-frontend.md`
