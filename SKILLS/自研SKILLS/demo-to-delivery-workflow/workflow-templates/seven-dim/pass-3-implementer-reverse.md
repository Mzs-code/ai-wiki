# Pass 3 — 实施者反向视角

> **触发**:reviewer 跑七维 review 的 Pass 3 时 Read 本文件。
> **上游**:[`../seven-dim-review.md`](../seven-dim-review.md) `<core_summary>`
> **强制字段**:Pass 3 finding 的输出格式中,`<implementer_reverse_code>` 字段为强制(机械校验)。Pass 3 finding 不带该字段视为伪 finding,L0 应判 agent 失格、重启 agent。详见 [`../review-output-template.md`](../review-output-template.md) `<finding_phase_format>`。

---

<pass_3_implementer_reverse>

伪装成"刚拿到 plan、要写代码的工程师"。对核心模块各模拟写 5–10 行真实代码,观察撞坑:
- 写 deps / router / startup / service / serializer 时,plan 假设是否被满足
- POST schema 是否能让 seed / demo 数据通过校验
- deps 抛 HTTPException 时,handler 链路上前端能拿到的最终 code 是哪个
- service 假设的 caller 状态(锁、事务、ContextVar、ORM session 状态)是否真被满足

**强约束 — endpoint handler 完整模拟**:每个写操作 endpoint(POST/PATCH/DELETE)至少模拟一次完整 handler 代码,**包括 response_model 反射路径**。重点验证:
- service 返 ORM 对象 + `response_model=XxxOut` + `from_attributes=True`:**XxxOut 声明的每个字段都必须能在 ORM 类上 `getattr` 到**;派生字段(default_project_guid / record_count / done_count 等统计/聚合字段)必须有显式的"service 层组装为 dict / endpoint 层手动拼"路径,否则反射时 AttributeError → 5xx
- service 返 tuple / dict 时,endpoint 怎么转 response_model — 拼装代码必须出现在 plan 某处
- set_cookie / Response 对象注入 / BackgroundTasks 调度等"endpoint 层独有"的代码,plan 是否有完整示例

**强约束 — async/await 字面扫描**:plan 中每段伪代码涉及 `async def` 函数调用时,**必须逐行检查调用点是否有 `await` 前缀**。常见漏点:
- helper(`insert_history_and_set_current` / `make_label` / `write_audit` / `load_active_record` / `gen_unique_guid_short` 等)定义为 `async def`,但 caller 漏写 `await` — coroutine 不执行,history 不写 / audit 不落 / 任务不调度,**运行时静默失败 + RuntimeWarning**(测试不挂但生产数据丢)
- 循环体 / `async with` 内多次调用 async helper,部分调用漏 await
- helper 早期同步、后期改 async,旧 caller 没同步更新
- 链式调用 `await foo(await bar())` — 内层 await 漏写 → 把 coroutine 当参数传

**强约束 — 模块 import 完整性扫描**:每段示意代码顶部 `import` / `from X import Y` 段,必须**对照正文用到的每个标识符**反查是否在 import 里出现。常见漏点(按命中频率排):
- FastAPI 端点示例 `Body(default=None)` / `Response` / `Query` / `Header` 用了但顶部 `from fastapi import APIRouter, ...` 没列(实施者直接 NameError 启动崩)
- lifespan / alembic env / startup hooks 用 `logger` / `asyncio.create_task` / `async_session_factory` / `start_periodic_sweeper` 但 import 段是早期版本未跟进
- 跨模块调用 `audit_service.write_audit_logout(...)` 类似形态 — 看似合理但被调函数**全文 0 处定义**;必须配合 Pass 2 grep `def write_audit_logout` 反证
- schema In/Out 类用了 `Annotated` / `Literal` / `Field` / `EmailStr` 但 import 段没补
- 前端 React / TS 示例同样致命:`useMemo` / `useState` / `forwardRef` / `dayjs` / `Button` / `useReactTable` / `apiClient` / `queryKeys` / `ApiError` 在示例正文里出现,但顶部 import 漏 — 直接 TS `Cannot find name 'X'`
- **测试代码 mock setup 双陷阱**(Vitest / Jest 都通用):
  - **vi.mock hoist 风险**:`vi.mock(factory)` 被 hoist 到文件顶部,factory 内引用外层 `const xxxMock = vi.fn()` 触发 `Cannot access 'xxxMock' before initialization`;必须用 `vi.hoisted(() => ({ xxxMock: vi.fn() }))` 把外层变量也提升
  - **mock path 与组件 import path 必须精确一致**:`vi.mock('@/hooks')` **不能**拦截 `from '@/hooks/useRollback'`(直接 path);组件应统一从 barrel(`'@/hooks'`)import,或测试侧补 `vi.mock('@/hooks/useRollback', ...)`;否则真实 hook 会跑到 `useQueryClient()` 在没有 QueryClientProvider 的测试环境里抛错
  - 排查口诀:看到 `No QueryClient set` / `Cannot read 'mutateAsync' of undefined` 类报错,先核对组件 import path 与 vi.mock 参数是否字面一致
- **修订后必须重跑**:**任何对示例代码块的修订(改 hook 实现 / 改组件结构 / 加 react-table 示例 / 改 derive 模式 / 切换 mock 方式)完成后,必须立刻把 import 段与该段正文用到的每个标识符再做一次比对**。修订引入的 import 漂移是七维方法论中最容易被忽略的回归源(见 Pass 7 同等强约束)

**强约束 — 启动期配置代码同等扫描**:Pass 3 实施者反向不只覆盖 service 层,还要扫:
- `app/main.py` `lifespan` 函数(secret 校验 / schema 检查 / sweeper 启动顺序)
- `alembic/env.py`(`fileConfig` 与 `set_main_option` 顺序、`target_metadata` 引入、async engine wrap)
- `app/core/config.py` `Settings` + 启动期 `enforce_*` 校验函数
- 任何"启动一次跑"的代码块(seed_dev / 健康检查 / dictConfig 日志配置)

这类代码混合 framework API + 业务 import,实施者通常按 plan 1:1 复制粘贴,顶部 import 段 / 调用顺序错就**服务起不来**(P0)。

**强约束 — 组合代码层(页面 / 编排 / 路由配置)同等扫描**:Pass 3 实施者反向**不能只扫原子层(service / hook / 单组件)**,还要扫"把原子组合成可运行单元"的代码层:
- 前端 `pages/*.tsx`:把 hook + 组件 + 路由参数(`useParams`)+ store 拼成完整页面,这是 hook 与组件契约的**真正消费者**
- 后端 `app/api/v1/*.py` router 装配:把 endpoint handler + dependencies + middleware 串到 APIRouter
- 任何"集成层 / 编排层 / page-level"代码 — 单看 hook 签名 + 单看组件 props 都能过 review,但**两者拼起来才暴露"hook 返回值与组件 props 不匹配 / 7 参数 hook 调用方传 4 参数 / page state 来源不一致"等组合层 bug**
- 验证手法:对每个"集成代码块"(page / router 装配 / `pages/*.tsx`)真敲 30–80 行完整代码,不能只给"形态描述 + 详见 §X" 占位
- 典型回归:`useRequirements(c, p, page, page_size, filter?, phase?, q?)` 7 参数签名定义在 hook 章节,但页面层 caller 只传 4 参数(把 filter 当 page_size)— **这是把 page 层当成"组件 + hook 自动拼起来"省略真敲代码的代价**

**强约束 — 派生字段在 update / PATCH 路径的语义验证**:Pass 6 跨层对照已要求"派生字段必须显式 supply 路径",但需细化两条路径分别扫:
- **create 路径**:派生字段初值(`record_count=0` / `done_count=0` 等)往往与"刚创建"语义自然吻合,反射默认 `int = 0` 看似正确 — 容易掩盖问题
- **update / get 路径**:同一字段在 update PATCH / 查询时**绝不能是 0**,必须显式查 DB 拼装;但实施者可能以为"create 没问题、update 也没问题"
- 修法:任何带派生字段的 Out schema,必须在 plan 内**同时给** create 路径 + update 路径 + get 路径的拼装代码

任何"写下去发现 plan 没说 / 说了但前后矛盾 / 现实跑不通"都是 issue。

</pass_3_implementer_reverse>
