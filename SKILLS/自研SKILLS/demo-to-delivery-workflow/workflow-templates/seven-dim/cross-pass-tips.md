# Pass 间交叉提示(经验沉淀)

> **用途**:不同 P 级 issue 倾向于在不同 Pass 暴露;Review 时按以下经验分配重心。
> **上游**:[`../seven-dim-review.md`](../seven-dim-review.md) `<core_summary>`

---

| 风险类型 | 最有效 Pass | 单 Pass 不够时怎么办 |
|---|---|---|
| **P0 类**:Out schema 字段在 ORM 上不存在 / response_model 反射 AttributeError | Pass 3(实施者反向)+ Pass 6 强约束 | Pass 6 跨层对照常被 schema 默认值掩盖,**必须 Pass 3 真敲 endpoint handler 反射代码** |
| **P0 类**:运行时框架行为陷阱(SAVEPOINT / ContextVar / hook) | Pass 4 | 单纯读 plan 文字不够,必须在脑中 simulate 真实执行 |
| **P0 类**:async 函数调用缺 `await`(coroutine 静默不执行) | Pass 3 强约束 + Pass 4 asyncio + Pass 7 grep 三重覆盖 | 任一 pass 单独扫都会漏(plan 伪代码读起来"逻辑对",IDE 没起,只有运行时 RuntimeWarning);必须 grep `async def` 函数名反查 caller |
| **P0 类**:ORM 默认值 `=0` / `=''` 业务语义错位(timestamp=0 被 sweeper 视作 stale / 关联 guid='' 撞唯一约束) | Pass 4 SQLAlchemy 子项 + Pass 5 覆盖范围 | 只看建表 SQL 默认值表面合理(类型对、不为 NULL);必须代入"sweeper / cleanup / cron / 唯一约束 / 范围比较" 等场景验证;每个 `default=...` 都问"什么场景会读它?读到时是否合语义?" |
| **P0 类**:endpoint / lifespan / alembic env 顶部 `import` 段缺漏(`Body` / `logger` / `asyncio` / `async_session_factory` 等)| Pass 3 强约束"模块 import 完整性扫描" | 单看 schema 表 / endpoint 表都对,只有真敲代码反查每个标识符是否在 import 里出现才暴露;特别注意"启动期配置代码"(lifespan / alembic env)经常遗漏 |
| **P0 类**:跨模块调用 `xxx_service.method(...)` 函数全文 0 定义 | Pass 1(链路追踪)+ Pass 2(grep 反证) 协同 | Pass 1 顺链路看似通了,实际被调函数不存在;必须 grep `def method` 计数 ≥1 反证 |
| **P0 类**:派生字段在 update PATCH / get 路径反射默认 0,语义错(create 路径假性正确掩盖)| Pass 3 实施者反向(双路径)+ Pass 6 跨层对照 | 创建路径默认 0 与"刚创建"语义吻合(看似正确),同字段在 update / get 路径默认 0 是错的;必须双路径分别模拟 endpoint handler |
| **P0 类**:短锁两段下中间段 race(写操作持锁 → AI 锁外回写覆盖 → 写操作静默丢失)| Pass 5 覆盖范围 + Pass 4 框架运行时 | 单看锁包了写操作就以为安全;必须代入"AI 短锁两段在锁外的 N 秒内,任何同字段写入都会被短锁段 2 apply 覆盖";加 `assert_no_active_ai_task` 守卫或 snapshot 比对 |
| **P1 类**:plan 自相矛盾 / 一个概念两份实现 | Pass 2 grep 反证 | 单纯 Pass 1 链路追踪两份都"通"链路就放过;必须 grep `def X` 计数 |
| **P1 类**:envelope code 翻译断裂 / 错误码细分丢失 | Pass 1(链路追踪)+ Pass 4 | 顺链路查 deps / service / handler / `_HTTP_CODE_MAP` |
| **P1 类**:大改后旧目录 / 索引未同步 | Pass 7 | 必须以"陌生人第一次读"心态扫尾 |
| **P0 类**:**修订引入的 import 漂移**(修后示例代码缺 / 多 import,实施者照抄 TS NameError 或 Lint warning) | Pass 3 import 完整性扫描 + Pass 7 修订重跑 | 第一轮 review 时 import 段是干净的,**修订后没重跑** Pass 3;每改一段示例代码必须立刻反查 import 段;典型表现:加 react-table 示例缺 `useMemo / Button / dayjs / queryKeys` import;改 derive 模式后 `useQuery` 留死 import + 新用 `ApiError` 漏 import |
| **P0 类**:**TS satisfies 语义错位**(plan 声称 OpenAPI 编译期校验,实际只校验本地一致性) | Pass 2 satisfies 反证 + Pass 6 跨层对照 | 两层独立错位:① 类型源头错位(本地 typeof PHASES[number] vs 远端 components['schemas']['Phase']);② satisfies 方向错位(`as const satisfies readonly Phase[]` 只能防本地多列,**不防本地漏列**;`satisfies Record<Phase, V>` 才是穷尽);两条 satisfies 必须协同(数组防多列 + Record 防穷尽),单用任一条都有漏 |
| **P0 类**:**测试 mock setup 错位**(vi.hoisted 缺失 + barrel 与直接 path 不一致) | Pass 3 真敲测试代码 + Pass 6 跨文件比对 | 两个独立陷阱:① `vi.mock` factory 闭包外层 `vi.fn()` 或 fixture 对象 → `Cannot access 'xxx' before initialization`(必须 `vi.hoisted` 把 fn + fixture 一起提升);② `vi.mock('@/hooks')` 不拦 `from '@/hooks/useRollback'` 直接 path → 真实 hook 跑到 useQueryClient 抛错;Pass 6 必须把"组件 import path"和"测试 vi.mock 参数"逐字比对,组件统一走 barrel 是最佳实践 |
| **P0 类**:**React Query / SWR queryKey 漏参数**(多调用方串数据,derive 类 hook 误判 not_found) | Pass 4 框架运行时强约束 + Pass 3 实操 | 看 plan 文字"queryKey 含 page / q"觉得"OK 该有的都有",但 queryFn 实际传 page_size=100 没进 key;另一调用方用 page_size=20 就把 cache 覆写;必须 grep queryFn 内 params query 字段集 vs queryKey 数组里 object 字段集逐个比对;漏任一参数即 P0;**任何带默认值的 query 参数也要从外部显式传入并进 key**,不能依赖 hook 内默认值 |
| **P1 类**:**单测 selector 与 E2E selector 不一致**(实施者写组件时不知道挂哪种 data-test) | Pass 6 跨层对照(测试两套规范跨文件) | 单测用通用名(`btn-edit`),E2E 用阶段化(`stage1-edit`)— 组件根本不可能同时挂两套;Pass 6 必须 grep 所有 `data-test=` 字符串,同一语义出现两种命名立刻收敛;最佳实践:容器 scope 名(`stage-{variant}`)+ 按钮通用名,单测 within() / E2E scoped CSS 共用 |
| **P0 类**:**组合层 caller 参数数 / 顺序与 hook 签名漂移**(hook 章节 7 参,page 注脚 caller 4 参 — TS 错 / cache 串数据) | Pass 3 实施者反向(扩到 page / 集成层)+ Pass 6 跨章节对齐 | 单看 hook 签名 OK,单看 page 注脚 OK,**两者放一起才暴露**;Pass 3 必须对 `pages/*.tsx` / 后端 router 装配等"组合层"真敲 30–80 行;Pass 6 必须 grep 每个 hook / store / 组件被引用的所有处,逐字对齐参数数 / 顺序 / 类型;**修订过 hook 签名后必须把所有 caller 重 grep 一遍**(Pass 7 的 import 漂移规则同样适用) |
| **P1 类**:**同 plan 不同段对同语义概念用不同模式**(同一 page 状态有的用 useState 有的用 store / 同一字段有的当 string 有的当 number)| Pass 6 跨章节对齐(强约束) | 单段独立看都合理,放一起就矛盾;实施者照近的段写,导致功能跨页面行为不一致;Pass 6 必须**显式枚举规约**:哪个域用哪种(Tenant 域用 store / Admin 域用 useState 等);任何同语义出现两种实现的处都要补"为什么不同 + 各用在哪"注脚 |
| **P0 / P1 类**:**守卫 / 拦截器跳转自循环**(跳到自己保护范围 / 回跳目标污染) | Pass 5 覆盖范围反向(强约束) | 三种典型陷阱:① 同源自循环(AdminRoute 跳 /admin/companies)→ 跳到 guard 范围外(/login)+ 配 ForceLogoutRedirect 清 user;② 回跳 from 污染(401 拦截器写 from='/login')→ 写时过滤 auth 端点 + 当前已在 /login,读时 from === '/login' ? fallback : from 双侧 sanitize;③ Location 对象 vs string pathname 类型不一致 → 全链路 string;**任何 navigate / Navigate 都问"目的路径会被同一 guard / 拦截器再次拦截吗"** |
| **P1 类**:**组件数据归属冲突**(dumb 与 smart 两路并存,同一数据 fetch 两次) | Pass 6 跨层对照(强约束) | 单看页面表"useXxx + <Table>"OK,单看组件契约"内部 useQuery"OK,**两者一起就重复请求 + 搜索参数无法注入 + 跨页面复用不同数据源失败**;Pass 6 必须 grep 组件实现内 useQuery / apiClient,vs 页面表是否描述"父拉 + 组件渲染" — 二选一,推荐 dumb(组件接 props,父用 hook 拉) |
| **P0 / P1 / P2 元层**:**修订完成后不跑"修订后强制扫描清单"** — 沉淀反模式 ≠ 自动应用 | [`revision-scan-checklist.md`](revision-scan-checklist.md) | 过去 N 轮的实证数据:**几乎每一轮都有 1–2 项是修订引入的**(import 漂移 / 同段对齐 / 旧命名残留 / 描述与代码不一致);每轮 plan 修订完成后**必须显式跑 Step 1–6 扫描清单**,并在交付时显式列出"6 步逐项做了"或"哪步跳过 + 为什么";不要依赖"我记得方法论里讲过" — 修订流程里把扫描清单当固定 checklist |
| **P0 类**:**修订引入的契约漂移**(组件 props 改 store-driven 后,旧 props interface / 测试文件 / 其它引用没同步删) | Pass 7 跨文件引用反查 | 改了一个文件的契约后,必须 `grep <symbol> all-plans/*.md` 反查所有引用;典型回归:HistoryDialog 改成无 props 的 store-driven 组件后,组件契约文件还留 `interface HistoryDialogProps`,测试文件还在 `<HistoryDialog open items=... />`,实施者按 props interface 写出另一套组件 |
| **P0 类**:**技术栈依赖版本未锁**(切栈后实施者拿到下一个主版本,破坏性更新让 plan 配置失效)| Pass 7 大改后 sanity scan(强约束) | 切栈 / 大改后必扫每个 dep 是否带主版本约束;Tailwind v3→v4(CSS-first 配置切换)/ RR v6→v7(future.v7_* + useNavigation 行为) / Zustand v4→v5(create 双调用)都有破坏性更新;技术栈表不能只写裸名字 |
| **P0 类**:**discriminated union 前端只 alias 不拆分支 / 不 narrow**(后端 Pydantic Annotated[A|B, Field(discriminator='X')] → 前端只 alias union → 消费侧 TS error)| Pass 3 实施者反向 + Pass 6 跨层对照(强约束) | 后端 union 必须在前端拆出 union + 全部分支三件套类型 alias;消费侧按 discriminator literal narrow(if data.applied === true / else),不能直接访问只在某分支存在的字段;codegen 实操时验 narrow 是否真生效;典型回归:RollbackOut 只 alias union,实施者写 data.content TS2339 |
| **P2 类**:文档 / example 一致性、死代码、字段计数标题 | 多 pass 混合 | 单 pass 都能扫到,合并阶段统一处理 |
