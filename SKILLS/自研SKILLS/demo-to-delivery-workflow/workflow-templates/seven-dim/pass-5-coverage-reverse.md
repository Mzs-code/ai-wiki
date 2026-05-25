# Pass 5 — 覆盖范围反向思考(漏了哪些场景?)

> **触发**:reviewer 跑七维 review 的 Pass 5 时 Read 本文件。
> **上游**:[`../seven-dim-review.md`](../seven-dim-review.md) `<core_summary>`

---

<pass_5_coverage_reverse>

每个机制都问"它不覆盖哪些场景?那些场景会怎样?":
- hook 只管 SELECT → bulk UPDATE / DELETE 漏过滤会怎样?
- 守卫只在 service 入口 → 直接调内部 helper 会绕开吗?
- 锁只锁 record_guid → 跨 record / 跨 project 一致性?
- 限流只对某 action → 高频低价 action 漏审计了吗?
- 软删用 status=0 → 是否每个查询都加了 status=1 过滤?(逐 service 列点检)
- **短锁两段设计下的"中间段 race"**:任何"持短锁 → 释放锁做长操作(网络/AI/IO) → 重新进短锁回写"的模式(典型:`run_*_job` 短锁段 1 置 running → 锁外调 AI → 短锁段 2 apply result),**任何在中间段抢锁写入相同字段的操作都会被短锁段 2 静默覆盖**。每个写同字段的操作都要问:"AI 跑期间我能跑吗?跑了之后会不会被 apply 覆盖?"
  - 典型陷阱:`rollback_ai` 持 record_scope 写 closure_questions → AI 短锁段 2 进锁 apply result 覆盖 rollback
  - 修法 A:写操作守 `assert_no_active_ai_task`,有 in-flight 任务直接 400 拒绝
  - 修法 B:AI 短锁段 2 进锁后比对 `task.input_snapshot` vs 当前 record 字段;不一致则放弃 apply(代价:实施复杂度高,需要前端配合)

**强约束 — 守卫 / 拦截器跳转必须全链路 sanitize 防自循环**:任何"出错就 navigate 到 X"的逻辑(路由守卫 / API 401 拦截器 / 角色守卫)都要问:"从 X 触发的请求再失败,还会跳到 X 吗?"
- 反例 1(同源自循环):`AdminRoute` 在 !is_admin 时 `Navigate to '/admin/companies'`,但 `/admin/companies` 仍被 `AdminRoute` 包裹 → 再判 !is_admin → 又跳 `/admin/companies` → ∞ 循环;修法:跳到不被同一 guard 保护的路径(如 `/login`),并配合清 user state(详见 ForceLogoutRedirect 模式)
- 反例 2(回跳目标污染):API 401 拦截器写 `state.from = location.pathname` 然后跳 `/login`,但**没过滤 location 自身就是 /login** 的场景(如登录页密码错 401)→ Login 登录成功后 `navigate(state.from)` 跳回 `/login` → ∞ 循环;修法:① 拦截器跳过 auth 端点自身的 401(`/auth/login` / `/auth/logout`)+ 跳过当前已在 /login 的场景;② Login 侧再 sanitize `from === '/login' ? '/admin/overview' : from` 兜底
- 反例 3(类型不一致 → 运行时跳错):ProtectedRoute 传 `state={{ from: location }}`(整个 Location 对象),Login 按 `state as { from?: string }` 读 → 实际 from 是 object 不是 string,navigate(object) 行为未定义;修法:全链路统一用 `from: location.pathname`(string)
- 验证手法:对每个 navigate / Navigate 调用,**追"目的路径是否被同一 guard / 同一拦截器再次拦截"** — 是 → 必有循环风险,要不就跳出守卫保护范围,要不就清前置状态;对回跳类逻辑(写 from / 读 from)**双侧都要 sanitize**(写时过滤 + 读时兜底),不能只防一边

列出每个机制的"未覆盖场景 + 后果"。

</pass_5_coverage_reverse>
