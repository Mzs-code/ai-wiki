# Pass 2 — Self-claim 验证

> **触发**:reviewer 跑七维 review 的 Pass 2 时 Read 本文件。
> **上游**:[`../seven-dim-review.md`](../seven-dim-review.md) `<core_summary>`

---

<pass_2_self_claim>

plan 内任何"对齐声明"都是高风险信号,逐项 grep 反证:

- "X 单一来源" → 全文搜 X,看是不是真的只一处定义
- "全 API 表面" / "完整列表" / "全表" → 列举所有应有项,对照表是否真的全
- "字段集与 schema 完全对齐" / "序列化器 1:1 对齐" → 把双方字段集列出来逐个比对
- "矩阵覆盖所有路径" → 按路径定义反向核对每一行
- "唯一入口" / "唯一 helper" / "唯一调用点" → **必须 grep `def <函数名>` 全文计数,期望恰好 1 处定义**;命中 ≥2 处就是回归
- 同一 helper 被多份伪代码示意时,**必须逐字对比函数体**;签名一致≠实现一致,两份不同实现实施者不知用哪份
- **跨模块调用名存在性反证**:plan 任何处出现 `xxx_service.method_name(...)` 形态,grep `def method_name` 全文计数,期望 ≥1 处定义;命中 0 → 调的函数压根不存在(典型回归:`auth_service.write_audit_logout` 调了但全文未定义,实施者照抄 → AttributeError)
- **TS / Pydantic 类型对齐 self-claim 反证(satisfies 语义陷阱)**:plan 任何处出现"X 类型与远端 schema 一致 / OpenAPI codegen 编译期校验"形态,**必须 grep 类型派生源头 + 校验方向**,两个独立反证:
  - **第一反证 — 类型来源**:确认 X 是从远端 schema 直接派生(`type X = components['schemas']['X']`)而**不是本地 `as const` 派生**:
    - 反例:`export const PHASES = [...] as const; export type Phase = typeof PHASES[number]` — Phase 来自本地 const,后端 OpenAPI 与本地完全脱钩
    - 正例:`export type Phase = components['schemas']['Phase']` — Phase 来自远端,本地 const 用 satisfies 校验子集
  - **第二反证 — satisfies 方向真值表**(单条 satisfies **不能**做穷尽校验,必须搭配主+次双防线):
    - `as const satisfies readonly X[]`(次防线):只校验"本地数组没有多列";**后端新增本地漏列时不会报错**(旧元素仍是新 union 子集)
    - `satisfies Record<X, V>`(主防线):校验"本地常量穷尽 X 全部 case";后端新增 / 本地多列 / 漏列 / 远端删除 都报错
    - 真正对齐:**两个 satisfies 同时用**(数组次防线 + 映射常量主防线),每次 enum 变化都至少触发一处 TS 报错
  - **核心区分**:`satisfies T` 只确保 value 符合 T 形状,**不约束 T 自身的来源**,**也不保证穷尽 T 全部 case**;声称"对齐远端"必须让 T 直接来自远端 + 用 `satisfies Record<T, V>` 做穷尽校验

**强约束**:Pass 2 不允许仅凭"读上去对"放过 — 任何 self-claim 都必须有 grep / 列举 / 字段集对比 三选一的反证步骤。

</pass_2_self_claim>
