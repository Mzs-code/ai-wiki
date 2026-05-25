# Pass 1 — 链路追踪(声明 → 实现 → 调用 → 异常路径)

> **触发**:reviewer 跑七维 review 的 Pass 1 时 Read 本文件。
> **上游**:[`../seven-dim-review.md`](../seven-dim-review.md) `<core_summary>`
> **配套**:[`../review-output-template.md`](../review-output-template.md) `<finding_phase_format>` — 输出格式

---

<pass_1_link_trace>

不要把每个章节当独立段落读。每发现一个"声明",立刻顺链路验到端:

- schema 字段 → service 序列化器 → 端点 response_model 是否一一对应
- 错误码细分 → 抛出点(deps / service)→ handler 翻译路径 → 实际下发给前端的 envelope code
- 状态机转换 → 守卫函数 → 入口 service → 对外端点
- 配置项 → 启动校验 → 运行时使用 → 失败兜底

任何链路第 N 跳断裂都是 issue。**特别留意"deps / service 抛 HTTPException 而非 BizError 子类"这类陷阱 — handler 翻译路径不同,前端拿到的 envelope code 会从细分降级到通用兜底**。

</pass_1_link_trace>
