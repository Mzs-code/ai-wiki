# Review 输出模板 + 修订后强制扫描清单

> 本模板供 SKILL.md 步骤 3(多轮 review)+ 每阶段末尾 L1 / L2 agent 钩子引用。
>
> **数字阈值**:见 [`../SKILL.md`](../SKILL.md) "数字阈值单一来源" 块。

---

## §1 review 的两阶段流程

<two_phase_review>

Claude Opus 4.7+(含 4.8)对"严格 P0/P1/P2 分级 + 必须给具体修法"的 prompt 会**自我过滤**:在 finding 阶段就把 low-confidence / uncertain findings 静默丢掉,导致 recall 下降。

为避免此反模式,本工作流把 review 拆为两个 phase:

### Phase A — Finding(覆盖率优先)

由 **L1 review agent** 执行。**目标 = coverage**:报告所有发现,包括 uncertain、low-severity、不确定能否修的。每条 finding 附 confidence + severity 估计;不自我过滤。

输出格式:见下 §2 `<finding_phase_format>`

### Phase B — Filtering(分级与修法)

由 **L0 人工 + L2 sanity-scan agent** 执行。基于 Phase A 输出做:
- P0/P1/P2 分级(允许 demote uncertain findings 到 P2 后再决定)
- 修法可执行性评估
- 区分 `contradiction`(必修)vs `design_tradeoff`(等用户拍板)
- 重复 finding 合并

输出格式:见下 §3 `<filtering_phase_format>`

### 边界澄清:任务要求"给修法"时怎么办

reviewer 接到的任务文案有时**同时要求** "Phase A finding" 和 "给可直接 Edit 的修法"。这两者本属于不同 Phase,直接混入 finding XML 会污染输出契约。处理规则:

1. **主体仍按 Phase A** `<finding_phase_format>` XML 输出(coverage 优先,不自我过滤)
2. **修法用 markdown 独立段附在末尾**,标题写 `## Phase B 提前修法(本任务额外要求,placeholder)`,并显式声明"本段是 reviewer 提前给的修法建议,不替代正式 Phase B `<filtering_phase_format>` 由 L0 + L2 产出的 `<fix>` 字段"
3. **不要**把 `<fix>` 字段塞进 `<finding>` 内 — Phase A finding 的 XML 契约必须保持纯净,Phase B filtering 才负责 P0/P1/P2 分级 + 修法

</two_phase_review>

---

## §2 Phase A — Finding 阶段输出模板

<finding_phase_format>

```xml
<review_findings reviewer="七维 review | 实施者反向 | ..." date="YYYY-MM-DD" round="N">
  <finding id="F-001" confidence="high|medium|low" severity_estimate="p0|p1|p2|unsure">
    <location>plans/01-data-model.md §3.2(行 124-130)</location>
    <original_quote>
      <!-- 引用 plan 原文 ≤ 6 行 -->
      The `record_status` field stores enum values: 'active', 'closed', 'archived'.
      Service layer ensures only state-machine-valid transitions occur.
    </original_quote>
    <observation>
      <!-- 你观察到什么(事实陈述) -->
      grep -n "'pending'" plans/*.md 在 plan §5.1 命中:demo 数据 seed 中存在 status='pending' 记录,但 plan §3.2 enum 未列 'pending'。
    </observation>
    <impact>
      <!-- 不修会导致什么 -->
      seed_dev 时 SQLAlchemy 会因 CHECK CONSTRAINT 失败,服务起不来(P0 候选);
      或 enum 改为 free-string 会让状态机失效(P1 候选)。
    </impact>
    <category>contradiction | design_tradeoff | uncertain</category>
    <pass_trace>Pass 2(self-claim grep 反证)</pass_trace>
    <!-- Pass 3 实施者反向 finding 强制带本字段;其他 Pass 可选 -->
    <implementer_reverse_code optional="true">
      <!-- 30-80 行真敲代码,展示卡壳点 / 反射错误 / queryKey 漂移等具体证据。
           Pass 3 finding 不带本字段视为伪 finding,L0 应判 agent 失格、重启。 -->
    </implementer_reverse_code>
  </finding>

  <!-- 更多 finding ... -->

  <pass_skipped>
    <!-- 显式列出跳过的 pass + 原因;reason 必须 ≥ 1 句完整解释(不接受单词级)+ 给可验证依据 -->
    <pass id="4" reason="小项目降级 — plan < 200 行无 ORM 层,Pass 4 框架运行时 simulate 无可 simulate 目标(详见 PROGRESS.md `agent_hook_mode: lightweight`)" />
    <!-- ✓ 合格 reason:"输入仅 3 段隔离 plan 片段,无完整 plan 文件用于 Pass 1 链路追踪(声明 → 实现 → 调用 → 异常路径)" -->
    <!-- ✗ 不合格 reason:"不适用" / "本次不需要" / "无相关内容" — 没给可验证依据 -->
  </pass_skipped>

  <loop_count>
    <!-- 本 finding 报告是第几轮 review;详见 §3.5 -->
    plan §3 部分:第 2 轮 review / 上限 3 轮
  </loop_count>

  <reflection optional="true">
    <!-- 哪些 finding 是单 Pass 暴露 vs 多 Pass 交叉暴露 -->
  </reflection>
</review_findings>
```

**Phase A 关键约束**:

- coverage > filtering:**low-confidence 也报**(标 `confidence="low"`),不要自己过滤掉
- 每条 finding 给 `<original_quote>` — ground in quotes,官方推荐做法
- `category` 区分:
  - `contradiction` = plan 自相矛盾(下游 Phase B 大概率判 P0/P1)
  - `design_tradeoff` = plan 设计选择,需要用户决定(Phase B 标 trade-off,不自动归 severity)
  - `uncertain` = 不确定是否真问题,需要 Phase B verify
- 没发现的 pass 显式说"本 pass 跑了 + 检查清单 + 0 finding"或 `<pass_skipped reason="...">`(不省略)
- **机械校验项**:Pass 3(实施者反向)的每条 finding **强制带 `<implementer_reverse_code>` 字段**(30-80 行真敲代码,行数尺度详见 [`review-agent-prompt.md`](review-agent-prompt.md) §2.5)。L0 在 Phase B filtering 时机械检查:Pass 3 finding 缺该字段 → 判 agent 失格,重启 agent。把"真敲代码"作为输出契约,治"看起来 OK"伪 finding。

</finding_phase_format>

---

## §3 Phase B — Filtering 阶段输出模板

<filtering_phase_format>

```xml
<review_filtered date="YYYY-MM-DD" round="N">
  <p0>
    <!-- 阻塞 commit / 阻塞进下一步 -->
    <issue id="P0-001" from_finding="F-001">
      <location>plans/01-data-model.md §3.2</location>
      <problem>plan §3.2 enum 漏 'pending',与 plan §5.1 demo seed 冲突</problem>
      <fix>
        <!-- 具体到能直接 Edit 的修订建议 -->
        Edit plan §3.2 enum 列表加 'pending' 或 Edit §5.1 seed 移除 'pending' 用例;选项见 design_tradeoff
      </fix>
      <impact>不修 → seed_dev 启动失败</impact>
      <pass_trace>Pass 2</pass_trace>
    </issue>
  </p0>

  <p1>
    <!-- 不阻塞 commit,但同 PR 内修 -->
    ...
  </p1>

  <p2>
    <!-- 可延后,记入 docs/todo.md -->
    ...
  </p2>

  <design_tradeoff>
    <!-- 等用户拍板的设计选择 -->
    <issue id="TO-001" from_finding="F-001">
      enum vs free-string 的取舍 — 选项 A: 严格 enum (失败快但需 migration);选项 B: free-string + service 层校验
    </issue>
  </design_tradeoff>

  <summary>
    P0: N | P1: M | P2: K | trade-off: T
  </summary>

  <gate_decision>
    <!-- P0=0 才放行;P0>0 时等用户逐条 ack 修法 -->
    放行 / 等用户 ack
  </gate_decision>
</review_filtered>
```

**Phase B 关键约束**:

- 每个 P0/P1/P2 必须能追溯到 Phase A 的 `from_finding="F-XXX"`(reviewable chain)
- 修法 `<fix>` 写到能直接 Edit 的粒度;**避免** "建议加强 / 完善 / 考虑改进" 等模糊语
- 用户 ack 之前 AI 不直接改代码(本约束属于流程纪律;并非通过 prompt 拦截,而是通过流程:Filtering 输出 → 用户读 → 用户说"改"才进 Edit 阶段)

</filtering_phase_format>

### §3.1 P0 / P1 / P2 分级定义

| 级别 | 定义 | 处理时机 |
|---|---|---|
| **P0 必修** | 直接导致 bug / 服务起不来 / 数据正确性破坏 / 编码出 bug | commit 前必修;P0=0 才放行(配合双轮验证,见 §3.5)|
| **P1 应修** | 不阻塞 commit 但会返工或一致性 bug,应同 PR 内修 | 同 PR 内修;延后则进 todo.md 高优 |
| **P2 后续优化** | 不阻塞 V1 / V2,可观察后再决定 | 记入 `docs/todo.md`,不强制本 PR 修 |

### §3.5 P0=0 双轮验证 + 回环 ≤3 轮 的衔接(M1 解决)

<loop_p0_clarification>

**回环计数从"修订引起的重 review"开始计**:

| 轮次 | 动作 | 回环计数 | 决策点 |
|---|---|---|---|
| 第 1 轮 | 初次 review → 发现 N 个 P0/P1/P2 | 0(初次,不计) | 修订 |
| 第 2 轮 | 修订后再 review(P0=0 目标) | 1 | P0=0 → 放行;P0>0 → 修订 |
| 第 3 轮 | 第二次修订后再 review | 2 | P0=0 → 放行;P0>0 → 修订 |
| 第 4 轮(若到达)| | 3(到达上限) | **触发 L0 拍板** |

**L0 拍板的决策选项**(不是 stop):
- 选项 A: 延长 1 轮预算(`loop_max_rounds` + 1)— 适合"还差 1-2 个回归 P0"
- 选项 B: 拆分剩余 P0 到 V2 — 适合"残余 P0 与 V1 范围弱相关"
- 选项 C: 重新评估 plan(P0 太多说明设计有问题)— 适合"回环计数 ≥ 3 仍未收敛"

**"P0=0 双轮验证"语义**:**第 2 轮 review 结束 P0=0** = 修订后再 review 一轮 P0=0 = 默认目标。

</loop_p0_clarification>

---

## §4 修订后强制扫描清单(6 步)

<revision_scan_6_steps>

每次完成修订后,把以下清单作为固定 checklist 跑一遍,不依赖记忆。

### Step 1 — import 完整性扫描

对每段刚改过的示例代码块,对照正文用到的每个标识符反查顶部 import 段;命中"代码用了但 import 没列"或"代码删了但 import 仍在" → 立刻补/删。

常见漏点:`within / useMemo / useState / forwardRef`(React)/ `ApiError / isApiError`(自定义)/ `Button / Skeleton`(shadcn)/ `dayjs / clsx / cva`(库)。

### Step 2 — 跨章节引用对齐扫描

对本轮改过的每个被引用对象(hook 签名 / store 字段 / 组件 props / 字段类型),grep 全部出现处;逐处比对:数量 / 顺序 / 类型逐字一致。

典型命令:
```bash
grep "useXxx(" plans/*.md
grep "<Xxx" plans/*.md
grep "interface XxxProps" plans/*.md
```

### Step 3 — 章节号 / 引用 / 目录树扫描

- 章节号连续:`grep -nE '^## [0-9]+\.' plan.md` 看序号有无断号
- 内部引用对齐:`grep -nE '详见 §[0-9]+' plan.md` 每处引用的章节号真存在
- 目录树同步:大改后文件树 / 索引列表与新增 / 重命名文件一致

### Step 4 — 残留旧命名 / 旧示例 grep

重命名:`grep '<旧名>' plans/*.md` 应只剩 contract 反例描述行;旧 props 模式 / 旧 import path / 旧 selector 命名同上。

### Step 5 — 反向回归 grep(本轮新引入的关键 token 都被采用)

`grep '<新 token>' plans/*.md` — 是否所有应用处都用了新写法。

典型:加 `queryKeyPrefix` helper 后,所有 hard-code 字符串都改用 helper 了吗?

### Step 6 — 显式列出"6 步逐项做了 / 跳过 + 为什么"

每轮修订完毕,跑一次以下 grep 输出 0 / 完整覆盖;旧 camelCase 标识符 0 残留(若本轮做过 snake_case 转换);修订涉及的所有跨文件 import / 引用都 grep 一遍。

显式声明每步状态;无法说清楚时,默认重跑一遍。

</revision_scan_6_steps>

---

## §5 revision-checklist.md 子模板(每轮修订提交)

每轮 review 修订完成后,在 `plans/archive/REVIEW-<reviewer>-<日期>-revision-checklist.md` 显式提交:

```markdown
# Revision Checklist — <reviewer 角色> / <日期>

## 本轮修订摘要
- 主 plan 修订位置:plan §X / §Y / ...
- IMPLEMENTATION 是否同步重拆:是 / 否 + 理由
- 修订类型:[局部修订] / [路线级修订]

## §4 6 步扫描清单逐项做了 / 跳过 + 为什么

### Step 1 — import 完整性
- [ ] 已做 — 命中漏点:...
- [ ] 跳过 — 原因:本次无示例代码改动

### Step 2 — 跨章节引用对齐
- [ ] 已做 — 命中漂移:...
- [ ] 跳过 — 原因:...

### Step 3 — 章节号 / 引用 / 目录树
- [ ] 已做 — ...

### Step 4 — 残留旧命名 grep
- [ ] 已做 — ...

### Step 5 — 反向回归 grep
- [ ] 已做 — ...

### Step 6 — 显式列出
- [ ] 已做 — ...

## 修订后 sanity-scan agent 跑过吗?
- [ ] 是 — agent 报告位置:`plans/archive/REVIEW-sanity-<日期>.md`
- [ ] 否 — 原因 + 待补时间

## 本轮修订引入的新 P0 / P1?
- 无 / 列出 + 处理方案

## 回环计数
- 本 plan 本部分 review 累计:第 N 轮 / 上限 3 轮
- 是否触发 L0 拍板:否 / 是 + 拍板结果(选项 A 延长 1 轮 / 选项 B 拆 V2 / 选项 C 重 plan)
```

revision-checklist.md 是"修订完成"的标志产物;未交付即视为修订未完成。

---

## §6 局部 review 范围模板(路线级修订轻量分支)

路线级修订触发"回到步骤 3 重 review"时,优先走局部 review(只跑受影响 pass),而非全 7 pass:

```markdown
# 局部 review 范围 — <修订主题> / <日期>

## 受影响维度(列出)
- 主 plan §X(数据模型 / API 契约 / ...)
- IMPLEMENTATION-<模块>.md §XY 阶段

## 受影响 Pass(从七维 7 个中筛选)
- Pass 1 链路追踪:需跑 — 因为...
- Pass 2 self-claim:跳 — 因为本次未涉及对齐声明
- Pass 3 实施者反向:需跑 — 涉及新代码路径
- Pass 4 框架运行时:需跑 — 改了 ORM 默认值
- Pass 5 覆盖范围:跳 — 未引入新机制
- Pass 6 跨层对照:需跑 — 涉及前后端契约
- Pass 7 sanity scan:必跑(任何修订都扫漂移)

## 启动 agent
- 启动 1 个 Plan agent;prompt 用 `review-agent-prompt.md` XML 6 槽位填(角色定位=局部七维 / 必读=主 plan 修订部分 + IMPLEMENTATION 影响阶段 + NOTES 路线级条目 / 输出=按上述受影响 Pass 跑 finding 阶段)

## 回环退出
- 本次修订重 review 累计:第 N 轮
- ≤3 轮 → 继续;>3 轮 → L0 拍板(选项 A/B/C,见 §3.5)
```

---

## §7 反模式清单(Pass 间交叉 — 哪些坑要靠多 Pass 协作发现)

参考清单(展示给 reviewer 学习,不是必须每条都扫):

- 把 plan 当独立段落顺次读完直接给 review,不跑 7 个 pass
- 接受 plan 的 self-claim 不验证("plan 自己说对齐了那就对齐")
- self-claim 验证只读不 grep("唯一入口"声明只检查口径,不实际全文搜函数定义计数)
- 完成大改就停手,不做最后一轮 sanity scan
- 只用 reviewer 视角,不切换到实施者视角写代码模拟
- 实施者反向视角只模拟 service 内部,不模拟 endpoint handler 的 response_model 反射路径
- 只看 plan 文字,不在脑中 simulate 框架运行时(SQLAlchemy / FastAPI / asyncio / React Query)
- 只检查"声明对不对",不检查"声明能不能在代码里落地"
- Pass 6 只对齐字段名,不验证"schema 字段是否真对应 ORM 物理列"(派生/统计字段陷阱)
- async 函数调用是否都 `await` 不扫,plan 伪代码里 coroutine 静默不执行的 bug 直接复制到生产代码
- 修订 plan 后不重跑 Pass 3 import 扫描 / Pass 7 sanity scan(修订引入的 import 漂移)
- 用"建议加强 / 待完善"等模糊语,对实施者无指导价值 — 用 `<original_quote>` + `<fix>` 具体化解决

(完整反模式清单见 `seven-dim/antipatterns.md`)

---

## §8 Pass 间交叉提示(经验沉淀)

不同 P 级 issue 倾向于在不同 Pass 暴露,Review 时按以下经验分配重心:

| 风险类型 | 最有效 Pass | 单 Pass 不够时怎么办 |
|---|---|---|
| schema 字段在 ORM 上不存在 / response_model 反射 AttributeError | Pass 3(实施者反向)+ Pass 6 | Pass 3 真敲 endpoint handler 反射代码 |
| 运行时框架行为陷阱(SAVEPOINT / ContextVar / hook)| Pass 4 | 在脑中 simulate 真实执行 |
| async 函数调用缺 `await` | Pass 3 + Pass 4 + Pass 7 三重覆盖 | grep `async def` 函数名反查 caller |
| ORM 默认值业务语义错位 | Pass 4 + Pass 5 | 代入"sweeper / cleanup / cron / 唯一约束" 等场景 |
| endpoint / lifespan 顶部 import 缺漏 | Pass 3 import 扫描 | 真敲代码反查每个标识符 |
| plan 自相矛盾 / 一个概念两份实现 | Pass 2 grep 反证 | grep `def X` 计数 |
| 大改后旧目录 / 索引未同步 | Pass 7 | 以"陌生人第一次读"心态扫尾 |
| 修订引入的 import 漂移 | Pass 3 + Pass 7 修订重跑 | 每改一段示例代码立刻反查 import |
| TS satisfies 语义错位 | Pass 2 satisfies 反证 + Pass 6 跨层 | satisfies 主+次双防线 |
| React Query queryKey 漏参数 | Pass 4 + Pass 3 实操 | grep queryFn 参数 vs queryKey |
| 守卫 / 拦截器跳转自循环 | Pass 5 覆盖范围反向 | 验证"navigate 目标是否被同一 guard 再次拦截"|

(完整交叉提示见 `seven-dim/cross-pass-tips.md`)

---

## §9 回环退出条件输出格式

任何回环(反问 ↔ agent ↔ 修订 ↔ 重 review)单条最大 `loop_max_rounds` 轮。超出 → 触发 L0 拍板(选项 A/B/C,见 §3.5),写入 PROGRESS §4 阻塞。

回环计数报告格式:

```xml
<loop_count_report>
  <loop name="plan §3 部分 修订→review" current="2" max="3" status="in_progress" />
  <loop name="IMPLEMENTATION §Y 修订→review" current="1" max="3" status="in_progress" />
  <loop name="反问 Z → 修订 → 反问" current="3" max="3" status="L0_decision_required" />
</loop_count_report>

<l0_decision_request optional="true">
  <position>PROGRESS.md §4 阻塞</position>
  <issue>具体问题 + 选项 A 延长 1 轮 / 选项 B 拆 V2 / 选项 C 重 plan</issue>
</l0_decision_request>
```

---

## §10 完整 issue few-shot(good / bad / edge)

### 完整 good issue

```xml
<finding id="F-007" confidence="high" severity_estimate="p0">
  <location>plans/03-service.md §4.3(行 89-94)</location>
  <original_quote>
    async def insert_history_and_set_current(record_id: str, payload: dict):
        await _insert_history(record_id, payload)
        _set_current(record_id, payload)  # ← 这里
  </original_quote>
  <observation>
    `_set_current` 在 plan §6.1 定义为 `async def _set_current(...)`,但 §4.3 调用未带 await。
    grep -n "async def _set_current" plans/*.md 命中 1 处定义,均为 async。
    grep -n "_set_current(" plans/*.md 命中 3 处调用,其中 §4.3 / §5.2 漏 await。
  </observation>
  <impact>
    coroutine 不执行 → current 状态不写入 → 业务"当前进行中"显示错位;
    生产 RuntimeWarning,测试可能不挂(timeout 容忍)。
  </impact>
  <category>contradiction</category>
  <pass_trace>Pass 3 async/await 字面扫描 + Pass 7 修订漂移</pass_trace>
</finding>
```

### 完整 bad issue(常见反模式)

```
- plan §4 建议加强一下 service 层的健壮性
```

**问题**:无 location 精确度 / 无 original_quote / 无 observation 具体性 / 无 impact 量化 / 无 category / 无 pass_trace / 无 confidence / 无 severity_estimate。

### Edge case issue(low-confidence)

```xml
<finding id="F-012" confidence="low" severity_estimate="unsure">
  <location>plans/02-api.md §3.5</location>
  <original_quote>
    The endpoint `POST /records` returns 201 with the created record.
  </original_quote>
  <observation>
    plan 未明示 Location header / ETag 等 HATEOAS 字段。
    我不确定本项目是否需要这些(SPA-only 用 fetch,不依赖 redirect);
    但若未来对接 server-rendered client 可能需要。
  </observation>
  <impact>
    短期无 — SPA 直接拿 body;
    长期 — 若加新 client 类型需要回头改。
  </impact>
  <category>uncertain</category>
  <pass_trace>Pass 5 覆盖范围反向</pass_trace>
</finding>
```

**说明**:Phase A 允许这类 low-confidence finding,Phase B(L0+L2)再决定是否升级到 P2 或 dismiss。这就是 finding/filtering 拆分的价值 — **uncertain 不会被静默丢掉**。
