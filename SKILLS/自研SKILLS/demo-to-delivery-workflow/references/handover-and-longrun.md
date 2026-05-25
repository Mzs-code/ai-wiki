# §5 退出条件 / 多 AI 接手 / V2 增量 / 长期续做

> 从 [`../SKILL.md`](../SKILL.md) §5 外移而来。这些规则只在**工作流晚期、跨 AI 接手、或长期搁置后续做**时触发,故不常驻 SKILL.md body。

---

## 退出条件

步骤 7 完成 → 本工作流职责结束。后续路径分支:

- **V2 增量** → 入口 C(从步骤 2 开始,**重跑 plan 自审**)
- **重大架构调整** → 入口 A(重做 demo,完整 7 步)
- **维护性增量** → 入口 B(从步骤 2 开始,跳步骤 1)

---

## 多 AI 协作接手协议

后续 AI 接手本项目(跨会话即跨 AI)时,接手 AI 走 **"提示流程,用户拍板"**;AI 不自动启动 sanity-scan agent:

1. Read PROGRESS.md 全文(尤其 §1 接手必读字段 — 前手最后决策 / 待拍板事项 / 风格偏好)
2. 按 PROGRESS.md §5 接手分支指针 Read 上下文:前手最后 3 次 commit(`git log -3 --oneline` + `git show <hash>`)+ 受影响的 plan / IMPLEMENTATION 章节
3. 提示用户(不自动启动 agent):
   > "我已读完 PROGRESS.md,前手最后在 **<阶段 N>** 的 **<子任务>**;是否需要我跑 1 个 agent 增量 sanity-scan 扫前手最后 N 次修订漂移?(推荐 / 跳过 / 自定义)"
4. 由用户拍板:
   - **推荐** → 启动 sanity-scan agent(prompt 用 [`../workflow-templates/review-agent-prompt.md`](../workflow-templates/review-agent-prompt.md) 6 槽位 XML,角色定位=接手 sanity-scan;输出接手风险点清单)
   - **跳过** → 直接按当前阶段([progress-template §5 分支 1-4](../workflow-templates/progress-template.md))进入工作
   - **自定义** → 按用户指示
5. 不重跑 plan 自审(避免接手成本过高)

---

## 长期续做特殊规则

- `> stale_warmup_milestone_days`:Read PROGRESS §6 里程碑摘要层(每阶段 1 条 + 路线级修订 1 条)+ 近期 10 条
- `> stale_warmup_overview_days`:额外重读 `plans/00-overview.md`(plan 设计意图)
