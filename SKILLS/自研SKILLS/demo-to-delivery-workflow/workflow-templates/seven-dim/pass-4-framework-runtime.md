# Pass 4 — 框架运行时语义

> **触发**:reviewer 跑七维 review 的 Pass 4 时 Read 本文件。
> **上游**:[`../seven-dim-review.md`](../seven-dim-review.md) `<core_summary>`

---

<pass_4_framework_runtime>

对 plan 涉及的核心框架,在脑中 simulate 真实行为:
- SQLAlchemy:`session.rollback()` 让 ORM 对象 expire/detach 后 caller 还能继续操作吗?hook 是只触发 SELECT 还是所有 statement?`expire_on_commit` 行为?`begin_nested` SAVEPOINT 失败后 caller 持有的对象状态?
- FastAPI:dependency 是 generator(yield)还是 return?BackgroundTasks 何时执行?response_model 校验 dict 还是 ORM?Pydantic 422 序列化与 envelope 是否一致?
- asyncio:Lock 是否跨进程?ContextVar 是否跨任务?cancel 时锁是否释放?**所有 `async def` 函数调用是否都被 `await`?未 await 的 coroutine 不执行,只产生 RuntimeWarning,测试可能不挂但生产功能静默失败**
- Pydantic v2:`model_fields_set` 区分"未传"vs"显式 null";`Optional[X] = None` 实际语义;`from_attributes=True` 反射规则
- DB:utf8mb4_general_ci 大小写敏感性、LONGTEXT default 限制、唯一约束并发行为
- **ORM / DB 默认值的业务语义验证**:列声明 `default=0` / `default=''` / `default='pending'` 在类型层面 OK,但**业务语义上可能立即出错**:
  - `BIGINT default=0` 用于毫秒时间戳:`0 ms = 1970-01-01`;任何 `WHERE col < now-X` 的 sweeper / cleanup / 过期检查会**立即命中刚 INSERT 但漏写 timestamp 的行**
  - `VARCHAR default=''` 用于关联 guid:在唯一约束场景下多行同时取 default 会撞 `uk_*` 唯一索引
  - `TINYINT default=1` 用于 `status` 软删列:批量 INSERT 漏指定时所有行都 status=1,与"软删默认 0,启用必须显式 1"的业务约定可能反向
  - **强约束**:每个 ORM 模型创建实例处都必须**显式列出**业务关键字段(timestamps / status / guid 关联列),不依赖 default;review 时对每个 `default=...` 都问"这个值会被哪个 cron / sweeper / cleanup / 唯一约束读取?读到时是否合语义?"

**强约束 — React Query / SWR 的 queryKey 必须包含影响响应的全部参数**:
- React Query / SWR / TanStack Query 等"按 key 缓存响应"的库,**queryKey 是响应 cache 的唯一身份**;两个调用方用同一 queryKey 但传不同 query 参数 → 第二次响应静默覆盖第一次,**第一次的数据"消失"**(典型灾难)
- 反例:`useQuery({ queryKey: ['projects', { page, q }], queryFn: () => apiClient.GET('/projects', { params: { query: { page, page_size, q } } }) })` — page_size 没进 key;调用方 A 用 page_size=20、调用方 B 用 page_size=100,共享同一 cache,B 的 100 条覆盖 A 的 20 条(或反之);A 看到的列表突然多/少了项,或 derive 类 hook(如 `useProject` 从列表 find 单项)在第 21+ 项目时误判 not_found
- 正例:queryKey 必须把 queryFn 用到的**每个 query 参数显式列入**:`['projects', { page, page_size, q, filter, phase }]`;参数有默认值也要从外部传入(`useProjects(c, page, page_size, q?)`)而非 hook 内 hard-code,否则不同调用方仍可能漏对齐
- 验证手法:**对每个 useQuery 示例,grep queryFn 用到的 params query 参数,逐个反查是否在 queryKey 内出现**;命中遗漏即 P0
- 同类问题:Apollo Client `useQuery({ variables })`、SWR `useSWR(key, fetcher)` 都遵循同一规则;React Query `useInfiniteQuery` 的 `pageParam` 也算

plan 假设的框架行为与实际行为不符 → issue。

</pass_4_framework_runtime>
