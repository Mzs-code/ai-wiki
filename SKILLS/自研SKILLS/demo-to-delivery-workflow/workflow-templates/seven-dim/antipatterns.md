# 七维 review 反模式清单(`<pitfall>` / `<correct>` 配对)

> **设计原则**:本清单用 `<pitfall>` / `<correct>` 配对块组织反模式。配对结构既保留反模式信息(`<pitfall>`),又给出正向出口(`<correct>`),还附 `<why>` 解释根本原因 — 让模型能从原理泛化到边界,而不是死背禁令。
> **上游**:[`../seven-dim-review.md`](../seven-dim-review.md) `<core_summary>`

---

## 输出约束(reviewer 启动前默读)

<output_constraints>

1. **按三档分级**:
   - **P0 必修**:直接导致编码出 bug / 服务跑不起来 / 数据正确性破坏
   - **P1 编码前应修**:会返工或导致一致性 bug,不阻塞但应同批修
   - **P2 后续优化**:不阻塞 V1,V2 / 上线后看监控反馈再决定
2. 每个 issue 必须包含:**具体行号引用 + 当前问题描述 + 建议修法 + 影响面**
3. 用具体改动位置和示例替代 "建议加强 X / 完善 Y" 类抽象建议
4. 区分 `<contradiction>` plan 自相矛盾(必修)和 `<design_tradeoff>` plan 设计选择存疑(标 trade-off 让用户决定)
5. 反思总结:本轮 review 中哪些 issue 是某个 pass 单独发现的,哪些需要多 pass 交叉才暴露 — 帮助后续校准

</output_constraints>

---

## 方法论级反模式(reviewer 行为)

<pitfall name="skip_seven_pass">
  <symptom>把 plan 当独立段落顺次读完直接给 review,不跑 7 个 pass</symptom>
  <correct>每个章节立刻顺链路验到端;7 个 Pass 都要跑完或显式 `<pass_skipped reason="...">`</correct>
  <why>plan 写得"读起来流畅" ≠ "实际能跑";Pass 1-7 是把"流畅" 拆解为可机械验证的 7 个独立视角</why>
</pitfall>

<pitfall name="accept_self_claim">
  <symptom>接受 plan 的 self-claim 不验证("plan 自己说对齐了那就对齐")</symptom>
  <correct>Pass 2 对任何 "X 单一来源 / 全 API 表面 / 字段集对齐" 等声明都 grep / 列举 / 字段集对比三选一反证</correct>
  <why>plan 的对齐声明在 90% 场景下是被人为遗忘后做的注脚,grep 反证常发现 ≥2 处定义或 0 处定义的回归</why>
</pitfall>

<pitfall name="self_claim_read_only">
  <symptom>self-claim 验证只读不 grep("唯一入口"声明只检查口径,不实际全文搜函数定义计数)</symptom>
  <correct>grep `def X` 全文计数,期望恰好 1 处定义;命中 ≥2 即回归 finding</correct>
  <why>"读上去对" 在 self-claim 上无法证伪;只有 grep 计数能给确定性证据</why>
</pitfall>

<pitfall name="no_sanity_after_big_change">
  <symptom>完成大改就停手,不做最后一轮 sanity scan</symptom>
  <correct>修订完毕跑 [`revision-scan-checklist.md`](revision-scan-checklist.md) 的 6 步,显式列出 "6 步逐项做了 / 跳过 + 为什么"</correct>
  <why>过去 N 轮的实证数据:**几乎每一轮都有 1–2 项是修订引入的**(import 漂移 / 同段对齐 / 旧命名残留)</why>
</pitfall>

<pitfall name="reviewer_no_implementer">
  <symptom>只用 reviewer 视角,不切换到实施者视角写代码模拟</symptom>
  <correct>Pass 3 真敲 30-80 行代码;Pass 3 finding 必须带 `<implementer_reverse_code>` 字段</correct>
  <why>看 plan 看不出"写下去发现 plan 没说 / 说了但前后矛盾 / 现实跑不通";只有真敲代码才暴露</why>
</pitfall>

<pitfall name="implementer_only_service">
  <symptom>实施者反向视角只模拟 service 内部,不模拟 endpoint handler 的 response_model 反射路径</symptom>
  <correct>每个写操作 endpoint 都模拟完整 handler 代码,包括 response_model 反射;派生字段必须有显式 supply 路径</correct>
  <why>派生字段(`default_project_guid` 等)在 Out schema 带 default 会掩盖反射 AttributeError;只有 response_model 反射模拟能暴露</why>
</pitfall>

<pitfall name="text_only_review">
  <symptom>只看 plan 文字,不在脑中 simulate 框架(SQLAlchemy / FastAPI / asyncio)运行时</symptom>
  <correct>Pass 4 对核心框架逐项 simulate;特别关注 SAVEPOINT / ContextVar / hook 触发 / await 完整性</correct>
  <why>plan 假设的框架行为与实际行为不符是 P0 类陷阱(典型:`session.rollback()` 后 ORM 对象 expire,caller 继续操作 AttributeError)</why>
</pitfall>

<pitfall name="declaration_no_landing">
  <symptom>只检查"声明对不对",不检查"声明能不能在代码里落地"</symptom>
  <correct>每个声明都顺到 endpoint / handler / service / model 真敲一次代码,看能否落地</correct>
  <why>声明的合理性(空中楼阁层)与可落地性(代码层)是两个独立维度</why>
</pitfall>

---

## P0 类反模式(数据正确性 / 服务起不来)

<pitfall name="schema_field_no_orm">
  <symptom>Pass 6 只对齐字段名,不验证"schema 字段是否真对应 ORM 物理列"(派生/统计字段陷阱)</symptom>
  <correct>每个 Out schema 字段都反向核对 ORM 物理列;派生 / 统计 / 跨表聚合字段必须显式标注 service 层组装路径</correct>
  <why>schema 字段带 default(`default_project_guid: str | None = None`)会让反射 AttributeError 被掩盖,生产 5xx</why>
</pitfall>

<pitfall name="async_missing_await">
  <symptom>Pass 3 / Pass 4 / Pass 7 都不扫 async 函数调用是否都 `await`;plan 伪代码里 coroutine 静默不执行的 bug 直接复制到生产代码</symptom>
  <correct>三重覆盖:Pass 3 字面扫描 + Pass 4 asyncio simulate + Pass 7 `grep -n "^async def "` 反查 caller</correct>
  <why>未 await 的 coroutine 只产生 RuntimeWarning,测试可能不挂但生产 history / audit / task 静默不落 — 这种 bug 测试不一定挂,但生产数据丢</why>
</pitfall>

<pitfall name="orm_default_business_semantic">
  <symptom>Pass 4 只看 ORM 默认值类型对不对(`BIGINT default=0` 类型 OK),不验证业务语义("0 ms 在毫秒时间戳语义下是 1970,会被 sweeper 视作 stale 立即误杀")</symptom>
  <correct>每个 `default=...` 都问"什么场景会读它?读到时是否合语义?";代入 sweeper / cleanup / cron / 唯一约束 / 范围比较等场景验证</correct>
  <why>ORM 默认值与业务语义的错位是 P0 级陷阱;类型 check 看不出 `0 ms = 1970-01-01` 这种语义偏移</why>
</pitfall>

<pitfall name="endpoint_import_missing">
  <symptom>Pass 3 实施者反向只扫 service 层,不扫 endpoint module 顶部 `import` 段(`Body` / `Response` / `Query` 等漏 import 直接 NameError 启动崩)</symptom>
  <correct>Pass 3 强约束"模块 import 完整性扫描" — 对每段示意代码顶部 import 段,对照正文用到的每个标识符反查</correct>
  <why>单看 schema 表 / endpoint 表都对,只有真敲代码反查每个标识符是否在 import 里出现才暴露</why>
</pitfall>

<pitfall name="startup_code_skipped">
  <symptom>Pass 3 实施者反向不扫 lifespan / alembic env / startup hooks 等"启动期配置代码"</symptom>
  <correct>Pass 3 必扫:`app/main.py` lifespan + `alembic/env.py` + `app/core/config.py` Settings + 所有"启动一次跑"代码块</correct>
  <why>这类代码混合 framework API + 业务 import,实施者通常 1:1 复制粘贴,顶部 import 段 / 调用顺序错就服务起不来(P0)</why>
</pitfall>

<pitfall name="cross_module_call_no_grep">
  <symptom>Pass 1 / Pass 2 看 `xxx_service.method(...)` 调用就以为存在,不 grep `def method` 反证</symptom>
  <correct>Pass 1 顺链路时配合 Pass 2 grep `def method` 计数 ≥1 反证;命中 0 即 P0(典型:`auth_service.write_audit_logout`)</correct>
  <why>链路看似通了,实际被调函数全文 0 定义;实施者照抄 → AttributeError</why>
</pitfall>

<pitfall name="derive_field_only_create">
  <symptom>Pass 3 / Pass 6 验证派生字段只看 create 路径(初值 0 与刚创建语义自然吻合掩盖问题),不验 update PATCH / get 路径</symptom>
  <correct>任何带派生字段的 Out schema,必须在 plan 内**同时给** create + update + get 三条路径的拼装代码;双路径分别模拟 endpoint handler</correct>
  <why>同字段在 update / get 路径默认 0 是错的,前端列表错位</why>
</pitfall>

<pitfall name="short_lock_two_phase_race">
  <symptom>Pass 5 看到写操作"已加锁"就放过,不验证"短锁两段 + 锁外长操作"模式下的中间段 race</symptom>
  <correct>对每个"持短锁 → 释放锁做长操作 → 重新进短锁回写"模式,问"AI 跑期间我能跑吗?跑了之后会不会被 apply 覆盖?"</correct>
  <why>典型:rollback 持锁写 closure_questions → AI 短锁段 2 锁外结束后进锁覆盖 → rollback 静默丢失;修法:`assert_no_active_ai_task` 守卫 或 snapshot 比对</why>
</pitfall>

<pitfall name="revision_import_drift">
  <symptom>修订 plan 后不重跑 Pass 3 import 扫描 / Pass 7 sanity scan;每改一段示例代码就引入"未使用 import"或"漏补 import"</symptom>
  <correct>Pass 3 / Pass 7 必须**对每个修订段落重跑**;每改一段示例代码必须立刻反查 import 段</correct>
  <why>第一轮 review 时 import 段是干净的,**修订后没重跑** Pass 3;过去 N 轮实证数据:几乎每一轮都有 1-2 项是修订引入的(加 react-table 示例时 `useMemo` / `Button` / `dayjs` 漏 import;改 derive 模式后旧 `useQuery` import 留下未删)</why>
</pitfall>

<pitfall name="satisfies_semantic_drift">
  <symptom>TS satisfies 语义错位 — self-claim 类型对齐做不到</symptom>
  <correct>两层独立反证:① 类型源头错位 — 必须 `type Phase = components['schemas']['Phase']`(远端派生),不是 `typeof PHASES[number]`(本地派生);② satisfies 方向错位 — `as const satisfies readonly Phase[]` 只防本地多列,**不防本地漏列**;必须协同 `satisfies Record<Phase, V>` 主防线穷尽校验</correct>
  <why>声称"OpenAPI codegen 编译期校验"或"satisfies 让漏配字段编译报错"时,单条 satisfies 不能做穷尽校验;两条 satisfies 必须协同(数组防多列 + Record 防穷尽)</why>
</pitfall>

<pitfall name="vi_mock_path_mismatch">
  <symptom>测试 mock 路径错位(Vitest / Jest 都通用):`vi.mock('@/hooks', ...)` 不会拦截 `from '@/hooks/useRollback'`</symptom>
  <correct>组件统一走 barrel(`from '@/hooks'`),hooks/index.ts 集中 re-export;或测试侧补 `vi.mock('@/hooks/useRollback', ...)`;Pass 6 必须把"组件 import path"和"测试 vi.mock 参数"逐字比对</correct>
  <why>实施者按测试 plan 写完跑测试,真实 hook 仍被调到 `useQueryClient()` 抛 "No QueryClient set"</why>
</pitfall>

<pitfall name="vi_mock_hoist_closure">
  <symptom>vi.mock factory 闭包外层变量(Vitest 经典 hoist 陷阱):`const mock = vi.fn(); vi.mock(path, () => ({ x: () => ({ mutateAsync: mock }) }))` → `Cannot access 'mock' before initialization`</symptom>
  <correct>用 `vi.hoisted(() => ({ mock: vi.fn() }))` 把外层 mock 也提升;fixture 数据(测试用对象 / 数组,如 `v3_latest, v2, v1`)也要进 `vi.hoisted`</correct>
  <why>`vi.mock` 被自动 hoist 到顶部,`const mock` 还没声明 → ReferenceError;Pass 3 实施者反向写测试代码示例时默认用 vi.hoisted</why>
</pitfall>

<pitfall name="query_key_missing_param">
  <symptom>React Query queryKey 漏参数 — 任何 `useQuery({ queryKey: [...], queryFn: () => apiClient.GET(path, { params: { query: { page, page_size, q } } }) })` 形态,queryKey 漏一个参数 → 多调用方共享 cache → 数据消失</symptom>
  <correct>Pass 3 真敲 useQuery 代码时,grep queryFn 用到的 params query 参数,逐个反查是否在 queryKey 内出现;漏任一即 P0;任何带默认值的参数也要从外部显式传入,不能依赖 hook 内默认值</correct>
  <why>典型回归:列表页用 page_size=20,derive hook 用 page_size=100,共享同一 cache;第 21+ 项目"消失",useProject derive 时误判 not_found</why>
</pitfall>

<pitfall name="combined_layer_skipped">
  <symptom>Pass 3 实施者反向只扫原子层(hook / 单组件),不扫组合层(page / router 装配);hook 单签名 + 组件单 props 各看都对,两者拼成 page 时才暴露 caller 参数数 / 顺序 / 类型不匹配</symptom>
  <correct>Pass 3 必须对每个"集成代码块"(`pages/*.tsx` / 后端 router 装配 / lifespan 编排)真敲 30-80 行完整代码,不能只给"形态描述 + 详见 §X" 占位</correct>
  <why>典型回归:`useRequirements(c, p, page, page_size, filter?, phase?, q?)` 7 参签名在 hook 章节,page 注脚 caller 只传 4 参(把 filter 当 page_size)→ TS 错或 cache 串数据</why>
</pitfall>

<pitfall name="cross_section_inconsistent">
  <symptom>Pass 6 不扫"同 plan 不同段的同语义概念是否一致"(plan 自相矛盾)</symptom>
  <correct>同一 hook / store / 组件 / 字段在 plan 不同章节出现时,签名 / 消费方式 / props / 数据形态必须逐项对齐;Pass 6 必须 grep 每个跨章节引用对象,逐处比对(数量 / 顺序 / 类型)</correct>
  <why>典型表现:契约章节改了 props 但调用样例没改、hook 签名加了参数但 caller 还是旧形态、同一概念有的段用 store 有的段用 useState 没明示规约;漂移即 P0 / P1</why>
</pitfall>

<pitfall name="guard_redirect_loop">
  <symptom>守卫 / 拦截器跳转不做全链路 sanitize(navigate 到自己保护范围内 / 回跳目标可能是当前页 → ∞ 循环)</symptom>
  <correct>对每个 navigate / Navigate 都问"目的路径会被同一 guard / 拦截器再次拦截吗";回跳类逻辑双侧 sanitize(写时过滤 + 读时兜底);全链路统一用 string pathname,不混 Location 对象</correct>
  <why>三种典型陷阱:① 同源自循环(AdminRoute 跳 /admin/companies);② 回跳 from 污染(401 拦截器写 from='/login');③ 类型不一致(Location 对象 vs string)</why>
</pitfall>

<pitfall name="component_data_ownership_split">
  <symptom>同一组件既被父注入数据又内部 useQuery(数据归属冲突):页面表说 "page 用 useXxx + <Table>",组件契约又写自己 `useQuery({ queryKey: ... })`</symptom>
  <correct>每个组件必须明示 dumb(props 注入) / smart(内部拉)二选一,**禁止两路并存**;推荐 dumb(组件接 props,父用 hook 拉)</correct>
  <why>两路并存:同一份数据 fetch 两次,搜索 / 筛选参数无法从父传入,跨页面无法复用不同数据源(`useAdminCompanies` vs `useAdminOverview().companies`)</why>
</pitfall>

<pitfall name="revision_no_scan_checklist">
  <symptom>修订完成后不跑"修订后强制扫描清单"(元层 — 沉淀反模式 ≠ 自动应用)</symptom>
  <correct>每轮 plan 修完后**必须显式跑** [`revision-scan-checklist.md`](revision-scan-checklist.md) 的 Step 1-6,并在交付时**显式列出**"6 步逐项做了"或"哪步跳过 + 为什么"</correct>
  <why>方法论里已沉淀的反模式(import 漂移 / 同段对齐 / 章节号 / 旧命名残留),修订时仍会踩;不跑这个清单,下一轮 review 几乎必然找出修订引入的回归</why>
</pitfall>

<pitfall name="dep_version_unlocked">
  <symptom>技术栈依赖版本未锁定 — package list 只写 `tailwindcss` / `zustand` / `react-router-dom` 裸名字不带版本约束</symptom>
  <correct>Pass 7 sanity scan 必扫:每个 dep 是否带主版本约束(`^6.21.0` / `^3.4.0` / `^4.5.0`);切栈 / 大改后必加</correct>
  <why>实施者 npm install 默认拿到下一主版本(可能是有破坏性更新的 v4 / v5 / v7);Tailwind v3→v4 / RR v6→v7 / Zustand v4→v5 都有破坏性更新;第一次跑 dev server 就因配置形态不对失效</why>
</pitfall>

<pitfall name="discriminated_union_no_narrow">
  <symptom>discriminated union 在前端只 alias 不拆分支 / 不 narrow(后端 Pydantic `Annotated[A|B, Field(discriminator='X')]` → 前端只 alias union → 消费侧 TS error)</symptom>
  <correct>① 类型 alias 把 union + 各分支都派生;② 消费侧按 discriminator literal narrow(`if (data.applied === true) { ... } else { ... }`);③ 真敲 5 行代码验 codegen 出的类型确实能 narrow;Pass 3 实施者反向 + Pass 6 跨层对照协同</correct>
  <why>典型回归:RollbackOut 只 alias union,实施者写 data.content TS2339 Property does not exist</why>
</pitfall>

<pitfall name="test_selector_two_sets">
  <symptom>测试 selector 单测 / E2E 命名不一致(P1 — 实施者无法落地两套):单测 `getByTestId('btn-edit')`,E2E `[data-test="stage1-edit"]`</symptom>
  <correct>全局 selector contract 单一来源:容器用 scope 名(`stage-{variant}`)+ 按钮用通用名(`btn-edit/save/cancel/confirm`);单测 within() / E2E scoped CSS 共用</correct>
  <why>组件根本不可能同时挂两套,跑单测过 / 跑 E2E 挂(或反之)</why>
</pitfall>

<pitfall name="vague_language">
  <symptom>用"建议加强 / 待完善"等模糊语,对实施者无指导价值</symptom>
  <correct>用 `<finding_phase_format>` 的 confidence / severity 标签替代;具体到 plan §章节 / 文件:行 + `<original_quote>` + `<fix>` 可直接 Edit 粒度</correct>
  <why>模糊语让实施者无法对应到具体修改;reviewable chain 也无法追溯</why>
</pitfall>
