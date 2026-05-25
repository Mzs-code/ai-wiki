# 步骤 1:Demo 业务文档化

> **配套**:[../SKILL.md](../SKILL.md) 总览 + 通用纪律 · 下一步 → [step2-plan-design.md](step2-plan-design.md)
>
> **入口适配**:A(新建)必跑;B(维护)/ C(V2)可跳(从已有 docs / AGENTS.md 抽业务说明);D(PoC)进工程模式时跑

---

**目标**:把 demo 的隐含业务沉淀为可读、可索引的文档,作为后续 plan 设计的事实底座。

**产物(按 demo 形态变体表)**:

| 形态 | README | FLOW | 第三件套 |
|---|---|---|---|
| **前端 SPA / 全栈 demo** | 业务/角色/状态机/边界/错误态 | ASCII 状态图 + 流程说明 + Modal 优先级 | `CODE_INDEX.md`(按文件行数 + 按功能查代码) |
| **后端 API demo**(curl 脚本 / Postman) | 业务/资源/状态机/鉴权/错误码 | 端点拓扑 + 调用顺序 + 重试 | `ENDPOINT_INDEX.md`(端点 → handler 函数) |
| **CLI 工具** | 命令族 / 输入输出契约 / 退出码 / 错误态 | 命令调用图 + 数据流 + 子进程拓扑 | `COMMAND_INDEX.md`(命令 → 子函数) |
| **Notebook / 数据科学** | 数据集 schema / 分析问题 / 可视化目标 / 假设 | cell 编号 → 分析步骤 → 输出图表 | `CELL_INDEX.md`(cell 编号 → 业务问题) |

**验收门类型**:文档型 5 项(详见 [`../workflow-templates/stage-template.md`](../workflow-templates/stage-template.md) §0.3 B)

**反问钩子(开头)— 按"必答类别 coverage"组织,每类至少 1 条**:

> 用"覆盖必答类别"(coverage 语言)而非"≥ N 条数量指标",避免凑数。每个类别至少 1 条,具体钩子条数视项目复杂度决定;不强制最少 5 条。

<asking_examples>

**必答类别**(本步骤必覆盖):

| 类别 | 至少 1 条 yes/no 钩子;每条可 grep / 可计数 / 可命名 |
|---|---|
| **业务边界** | demo 业务一句话能否说清?涉及哪些业务实体? |
| **角色清单** | 列具体角色名(非泛"用户");例:管理员 / 终端用户 / API 调用方 |
| **主场景路径** | 覆盖 demo 演示过的每条路径,逐条命名(SC-01 / SC-02 / ...) |
| **状态机** | 节点数 = ?边数 = ?边界 / 不可逆约束有声明? |
| **业务术语词典** | 关键术语 grep 在三件套全部出现 |
| **形态自适应** | demo 形态对应的三维度都已调通?(见下方形态表) |

形态 → 三维度对应:
- SPA = 视觉 / 交互 / 功能
- 后端 API = 输入 / 输出 / 错误码
- CLI = 输入 / 输出 / 退出码
- Notebook = 输入数据 / 分析步骤 / 可视化输出

**反问钩子 good vs bad**:

✓ "角色清单是否 ≥ 3 个具体角色名:管理员 / 终端用户 / API 调用方?" — 可命名
✓ "状态机节点数 = 3(草稿/已提交/已查看),`grep -nE '(草稿|已提交|已查看)' demo/FLOW.md` 命中 ≥ 3 行?" — 可 grep
✗ "看一下角色定义" — 不可答
✗ "状态机大致对吗?" — 不可验证

</asking_examples>

**Agent 钩子(末尾,L0+L1+L2 三层)**:

> **通用 agent 规则**:详见 [`../SKILL.md`](../SKILL.md) §0.4(为什么用多 subagent)+ §2 第 6 条(三层 review 定义)。本文件只列本步骤特有内容。
>
> **本步骤特有 — 小项目降级出口**:demo 代码 < 500 行 **或** 主场景路径 ≤ 3 条时,**L1 反向重建可降为 L0 用户对照 + 1 个简版 sanity-scan**(跳过反向重建 subagent),在 PROGRESS.md 顶部元信息标注 `step1_l1_mode: lightweight (reason: demo<500 loc OR scenes<=3)`。

- **L0 人工**:用户读三件套核心段,确认业务理解一致(给 yes/no 反馈)
- **L1**:启动 1 个 Explore agent;prompt 用 [`../workflow-templates/review-agent-prompt.md`](../workflow-templates/review-agent-prompt.md) XML 6 槽位填:
  - `<role>`:反向重建业务流程(不看 demo 只读三件套反推业务,与原 demo 对照)
  - `<must_read>`:三件套 + 原 demo(主)+ [`../workflow-templates/review-output-template.md`](../workflow-templates/review-output-template.md) `<finding_phase_format>`(输出格式)
  - `<output_format>`:反推业务流程 vs 原 demo diff 报告;coverage 优先,带 confidence
  - `<constraints>`:重画状态图;反推流程节点差异 ≤ N(N = 原节点 × 10% 向上取整,最小 1)
  - `<failure_examples>`:首轮用 `<no_prior_examples/>`;或"常见漂移:角色清单不完整 / 状态机节点遗漏边界态"
  - `<user_context>`:项目类型 / 当前阶段 / 已反问
- **L2**:修订后跑 sanity-scan(三件套间引用一致性);prompt 同 XML 6 槽位填,角色定位=sanity-scan,只跑 6 步扫描清单(详见 [`../workflow-templates/review-output-template.md`](../workflow-templates/review-output-template.md) `<revision_scan_6_steps>`)

**细节**:三件套形态本项目用纯 HTML+JS+CSS 零构建 demo;其他形态见上表。

**本项目示例**:`demo/README.md` + `demo/FLOW.md` + `demo/CODE_INDEX.md`(本仓库实物)
