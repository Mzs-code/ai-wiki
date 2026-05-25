# 步骤 6:Demo 对比调优

> **配套**:[../SKILL.md](../SKILL.md) 总览 + 通用纪律 · 上一步 → [step5-execution.md](step5-execution.md) · 下一步 → [step7-doc-system.md](step7-doc-system.md)
>
> **入口适配**:A(新建)必跑;B(维护)/ C(V2)/ D(PoC)可跳(无对照 demo)

---

**目标**:工程版本在视觉 / 交互 / 功能三维度对齐 demo;差异要么补齐要么记 TODO。

**产物**:
- 视觉走查 commit(像素差 / 配色 / 间距 / 圆角 / 阴影 / 字号)
- 交互回归 commit(防抖 / 节流 / loading / 错误态 / 空态 / 边界态)
- 功能差异补齐 commit

**验收门类型**:代码型(以 dev server 实跑通过为核心,对应 SKILL.md §2 第 9 条"测试不验证功能正确性")

**反问钩子(开头)— 按必答类别 coverage 组织,每类至少 1 条**:

<asking_examples>

| 类别 | 至少 1 条 yes/no 钩子;每类不限条数(项目复杂度决定) |
|---|---|
| **demo 偷懒点对照** | 列出 demo 偷懒 mock(具体到文件:行),逐条标 V1必修 / V2 / 不修(demo 演示态)/ 无法判定(先查 NOTES,再反问)|
| **demo 未演示工程态** | 列出 demo 没演示但工程要补的态(loading / 错误兜底 / 空数据 / 网络断连),具体路径 |
| **实测入口跑过的主路径** | 列出实测主路径(SPA = URL;后端 = curl;CLI = 命令;Notebook = cell 重跑),每条标"跑通 / 失败 / 跳过 + 原因" |
| **测试不等于功能完成**(WORKFLOW §2 第 9 条) | 类型检查 / 测试套件验证代码正确性,**不验证功能正确性** — 实测入口是验收门必填项 |

**Good vs Bad**:

✓ "demo 偷懒 mock 清单:`demo/index.html:142 假数据 / demo/api.js:55 setTimeout 假延迟`,逐条标处理档位?" — 可定位 + 可分类
✓ "SPA 主路径 SC-01 / SC-02 / SC-03 在 dev server 实跑通过?每条标 URL + 截图?" — 可命名 + 可证据
✗ "demo 对比差不多了" — 不可验证
✗ "工程版本看上去和 demo 一致" — 无具体路径

</asking_examples>

**Agent 钩子(三层)**:

> **通用 agent 规则**:详见 [`../SKILL.md`](../SKILL.md) §0.4 + §2 第 6 条。本文件只列本步骤特有内容。

- **L0 人工**:用户对照 demo 走 3 条典型路径,给"差异 / 缺失"清单
- **L1**:启动 1 个 Explore agent;prompt 用 [`../workflow-templates/review-agent-prompt.md`](../workflow-templates/review-agent-prompt.md) XML 6 槽位填:
  - `<role>`:陌生用户视角 — 对照 demo 走 3 条典型路径,记录每个视觉 / 交互差异
  - `<must_read>`:demo 三件套 + 工程产物 + 实测入口跑通报告
  - `<output_format>`:差异清单(每条标推荐处理档位:V1必修 / V2 / 不修 / 无法判定);coverage 优先,带 confidence
  - `<constraints>`:真跑 dev server / curl / CLI(不接受"只看代码")
  - `<failure_examples>`:首轮 `<no_prior_examples/>`
  - `<user_context>`:...
- **L2**:修订后 sanity-scan

**细节**:差异分四档处理 — V1 必修 / V2 计划(进 TODO.md)/ 不修(demo 演示态,在 PROGRESS.md §4 标 `[demo-保留态]`)/ 无法判定(优先查 NOTES,再中段反问用户 + TODO)
