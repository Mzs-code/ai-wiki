# Pass 6 — 跨层对照(UX ↔ API ↔ 数据模型 ↔ service 实现)

> **触发**:reviewer 跑七维 review 的 Pass 6 时 Read 本文件。
> **上游**:[`../seven-dim-review.md`](../seven-dim-review.md) `<core_summary>`

---

<pass_6_cross_layer>

任何 UX 描述都往下追到数据模型;任何字段都往上追到是否真被用:
- UX 说"前端能判断 X" → 数据模型有支撑 X 的字段 / 时序吗?
- 数据模型有字段 Y → 哪个 API / UX 在用?用法与 plan 描述一致吗?
- API 端点返回字段 Z → service 真的查 / 写 Z 吗?
- service 写了某字段 → 哪个端点 / UX 在读它?

不闭环的具体行号对引用都列出来。

**强约束 — schema 字段必须对应物理列**:
- schema 字段名与 ORM 列名对齐**不等于**字段真实存在
- 任何"派生字段 / 统计字段 / 跨表聚合字段"出现在 Out schema 时,**必须显式标注 service 层如何组装**(返 dict / tuple / endpoint 层手动拼);只声明 `default_project_guid: str | None = None` 这种带 default 的字段会掩盖反射 AttributeError
- 反向核对:每个 Out schema 的字段 → ORM 对应物理列?若否 → 谁负责供这个字段?supply 路径是否在 plan 里写明?

**强约束 — 同 plan 不同段的同语义概念逐项对齐**:Pass 6 跨层对照不只跨"前端 ↔ 后端"或"UX ↔ 数据模型"层,还要扫**同一份 plan 内不同段落引用同一概念时是否一致**:
- 同一 hook 的**调用签名**:hook 章节给的形参列表(7 参) vs 页面 / 注脚里的实际 caller(4 参) — 数量 / 顺序必须逐字一致
- 同一 store 字段的**消费方式**:有的页面用 `useState(1)` 自管 page,有的页面用 `useTenantUiStore.currentPage` 共享 — 同 plan 出现两种模式必须明示规约(哪个域用哪个)
- 同一组件的**props 契约**:契约章节 `interface XxxProps { ... }` vs 调用样例 `<Xxx ... />` 传的 props — 字段集必须对齐;一边改契约另一边漏改是典型修订漂移
- 同一字段的**数据形态**:有的段说"id 是字符串 guid",有的段示例传 `id: 1` number,Pass 6 必须 grep 同名字段在不同段的类型 / 字面值
- 验证手法:对每个跨章节出现的"被引用对象"(hook / store / 组件 / 字段),grep 全部出现处,逐处比对参数 / 类型 / 用法
- 典型回归:`useRequirements` 在 §12.2 是 7 参签名,§11.2 注脚 caller 4 参 — 同 plan 自相矛盾,实施者按近的写,跑起来 TS / runtime 错位

**强约束 — 组件数据归属(dumb / smart)单一来源**:任何带数据(列表 / 详情 / 派生集)的组件,plan 必须明示数据归属 — **要么父页面拉数据通过 props 注入**(dumb 组件,组件内 0 useQuery / useMutation),**要么组件内自管数据**(smart 组件,父只传配置不传数据);**禁止"父也拉、组件也拉"两路并存**:
- 反例:页面表 / 路由章节描述 `pages/AdminCompanies.tsx` 用 `useAdminCompanies(...)` 拉数据 + `<CompanyTable>`,但 CompanyTable 组件契约里又自己 `useQuery({ queryKey: queryKeys.admin.companies(...) })` — **同一份数据 fetch 两次**(浪费请求,且搜索 / 筛选参数无法从父传入,AdminOverview 也无法复用 `useAdminOverview().companies`)
- 修法 A(推荐 — dumb 组件):组件 props 接 `rows / page / pageSize / total / onPageChange / onXxx 回调`;父页面用对应 hook 拉数据后注入;组件只渲染 + 转发事件 — 这种组件可被多个父页面用不同数据源(列表端点 / overview 端点)复用
- 修法 B(smart 组件):组件内部 `useQuery`,父只传 `mode` / `filter` 等配置;父页面对应 page 不再调同 endpoint;**但适用面窄**(组件不能跨页面复用不同数据源)
- 验证手法:对 plan 每个组件契约,grep `useQuery|useMutation|apiClient\.` 在组件实现内是否出现;同时 grep 该组件在页面表 / 路由章节是否被描述为"父拉 + 组件渲染" — 若组件内有 useQuery 但父也描述拉同 endpoint → P1(数据归属冲突);**修法必须二选一,不允许两路并存**
- 典型回归:加 react-table 示例时让组件自己拉数据求"完整可跑",但忽略了页面层早已描述"useAdminCompanies + <CompanyTable>"组合 — 修订引入的契约漂移,Pass 6 跨章节对齐 + Pass 3 实施者反向(组合层真敲)双重失守

**强约束 — discriminated union 在前后端两侧的 narrow 落地**(来源:前端 plan 七维 review 2026-05-09 P0-13):
- 后端用 Pydantic `Annotated[A | B, Field(discriminator='X')]` 等 union 形态时(典型:`RollbackOut = Annotated[RollbackTextOut | RollbackAIOut, Field(discriminator='applied')]`),**前端必须**:
  - **类型 alias 三件套**:把 union + 各分支都从 OpenAPI 派生(`type RollbackOut = components['schemas']['RollbackOut']; type RollbackTextOut = components['schemas']['RollbackTextOut']; type RollbackAIOut = components['schemas']['RollbackAIOut']`);只 alias union 不拆分支 → 消费侧 TS narrow 不出来
  - **消费侧按 discriminator literal narrow**:`if (data.applied === true) { /* RollbackAIOut narrow */ } else { /* RollbackTextOut narrow */ }`;**绝不能直接访问只在某分支存在的字段**(`data.content` 只在 RollbackTextOut,在 union 上访问 → `TS2339 Property 'content' does not exist on type 'RollbackOut'`)
  - **OpenAPI codegen 必须真出 discriminator narrow**:某些 codegen 工具对 Pydantic `Annotated + Field(discriminator=...)` 不一定生成正确的 TS discriminated union 形态 — 实操时 verify `data.applied === true` 是否真能让 TS 推 narrow 出 RollbackAIOut(走 schema/lib 文档,或本地写 5 行真 narrow 代码验证)
- 反向核对(Pass 6):对每个后端 union schema,grep 前端类型 alias 章节是否同时把 union + 全部分支都派生;对每个前端消费侧 if/switch,grep 是否使用 discriminator literal 分支(而非访问只在某分支存在的字段)

**强约束 — 测试 selector contract 单测 / E2E / 组件实现三方一致**:
- 任何带 `data-test` / `data-testid` / `aria-label` 等可测试属性的 plan,**必须定义全局 selector contract**(一份命名约定,单测 / E2E / 组件源码三方共用),而**不是单测一套、E2E 另一套**
- 反例:单测用通用名 `getByTestId('btn-edit')`,E2E 用阶段化名 `[data-test="stage1-edit"]` — 实施者写组件时不知道挂哪个,挂了只覆盖一边;且单测渲染单组件 OK,RequirementDrawer 整体渲染 4 份 StageCard 时 `getByTestId('btn-edit')` 抛 "found multiple elements"
- 正例(推荐架构):
  - **容器节点**用 `data-test="<scope>-<id>"`(如 `stage-description` / `stage-closure_record`,直接对应 props.variant 字面量)
  - **原子按钮 / 输入**用通用名(`btn-edit` / `btn-save` / `btn-cancel` / `btn-confirm` / `textarea` / `content`)— 跨组件可复用
  - 单测用 `within(stage).getByTestId('btn-edit')` scope 选;E2E 用 `[data-test="stage-description"] [data-test="btn-edit"]` scoped CSS
  - **不允许**阶段化按钮命名(`stage1-edit` / `stage3-confirm-trigger`)— ID 与 variant 解耦,单测/E2E 容易漂移成两套
- 反向核对:对 plan 任何示例 `data-test=...` 字符串,grep 全部 plan 文件计数;同一语义 ID 出现两种命名(通用 vs 阶段化、kebab vs snake) → 立刻收敛为一套,Pass 7 sanity scan 同步

</pass_6_cross_layer>
