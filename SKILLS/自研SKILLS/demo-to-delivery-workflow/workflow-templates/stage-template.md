# IMPLEMENTATION 单阶段模板 + 验收门双模板

> 本模板供 SKILL.md 步骤 4(拆分 IMPLEMENTATION)引用。新项目按此填 `IMPLEMENTATION-<模块>.md` 或单模块 `IMPLEMENTATION.md`。
>
> **数字阈值**:见 [`../SKILL.md`](../SKILL.md) "数字阈值单一来源" 块,本文件不重复声明。

---

## §0 IMPLEMENTATION 文件总体结构

每份 `IMPLEMENTATION-<模块>.md` 含:

```
# IMPLEMENTATION-<模块>.md(模块名)

> 一句话:本模块按阶段 X0 → XN 顺序执行,每阶段验收门通过才进下一步。

## §0.1 阶段全景表
## §0.2 通用约束(8 条,引 SKILL.md §2)
## §0.3 验收门通用模板(代码型 / 文档型双模板)

## §X0 第 0 阶段
## §X1 第 1 阶段
...
```

---

## §0.1 阶段全景表(模板)

| # | 阶段号 | 目标(一句话)| 关键交付(文件/函数清单)| **验收门类型** | 退出门关键口令(grep / 命令)| 参考耗时 |
|---:|---|---|---|---|---|---|
| 0 | X0 | 环境准备 | `.env` + venv + DB schema | 代码型 | `mysql -e 'SELECT 1'`;`python -c 'import X'` | 0.5 天 |
| 1 | X1 | ...  | ...  | 代码型/文档型 | ... | ... |

**填表规则**:
- 阶段号(X 替换为模块前缀):多模块项目用 `<模块前缀>X`(如 `API0` / `UI0` / `CLI0` / `ETL0`);单模块项目可纯数字
- 验收门类型:代码型 用 §0.3 代码型 5/6 项;文档型 用 §0.3 文档型 5 项;混合阶段拆成两个相邻阶段
- 关键交付:具体到文件路径 / 函数签名 / 类名
- 退出门关键口令:可命令行执行(grep / curl / wc / pytest);避免 "应该都过了" 模糊判定

---

## §0.2 通用约束(对应 SKILL.md §2)

每个阶段遵守 SKILL.md §2 的 9 条通用纪律。**本文件不重复**,详见 [`../SKILL.md`](../SKILL.md) §2。

**重点摘要**:
- 第 1 条:plan / demo 是事实底座(plan 模糊优先查 NOTES,再反问)
- 第 3 条:Commit 由 settings.json hook 拦截(机制层);AI 完成阶段 + stage + 提示用户即可,**不在 prompt 层重复列出"禁止执行的 git 命令清单"**
- 第 4 条:失败即停(5/5 或 6/6 验收门)
- 第 6 条:反问钩子 + 三层 review + 回环管理(P0=0 双轮 + ≤3 轮 + L0 拍板选项 A/B/C)
- 第 9 条:测试验证代码正确性,不验证功能正确性

---

## §0.3 验收门双模板

### A. 代码型验收门(5/6 项)

适用阶段:SKILL.md 步骤 5(分阶段实施)+ 步骤 6(demo 对比调优)的代码阶段。

每阶段验收门按以下打分,**5 项全过**(无第 6 项触发时 5/5;第 6 项触发时 6/6):

| 项 | 通过标准 | 实际口令样例 |
|---|---|---|
| **1. 代码到位** | plan 指明的文件/函数/类全部存在,签名 1:1 一致 | `grep -rn 'def my_func' app/` 命中 1 |
| **2. 单测绿** | 本阶段引入的 `tests/unit/test_*.py` 全绿 | `pytest tests/unit/test_X.py -q` 退出码 0 |
| **3. 集成测/组件测/契约测**(按项目类型变体) | 后端=集成测(httpx 实连数据库/外部服务);前端=组件测(RTL + jsdom);CLI=契约测(golden output 比对) | `pytest tests/integration -q` / `vitest run tests/components` / `pytest tests/contract -q` |
| **4. 手工 smoke** | curl / dev server / CLI / Notebook cell 实跑一条主路径,响应 + DB 落库 / stdout / 可视化输出符合预期 | `curl :8000/api/v1/health` → 200;`mycli foo --dry-run` → 期望输出 |
| **5. grep 防回归** | 本阶段强约束 grep 命令运行 **0 hit** | `grep -rn '<旧命名>' app/` 期望 0 |
| **6. 跨模块/跨进程契约对齐**(触发条件出现时强制) | 关键验收点逐项 Read 上游模块代码反查;后端 curl 实连外部服务、前端 curl 后端真路由、CLI 真子进程 stdout 比对 | `curl :8000/api/v1/X` 与前端 `apiClient.GET('/X')` 字段集 diff 为空 |

**第 6 项触发条件**(任一命中即强制 6/6):
- 阶段产物依赖另一模块的契约(API 端点 / DB schema / CLI stdout 格式)
- 跨进程通信(子进程 / 微服务 / RPC)
- 跨语言/跨运行时(前后端 / Python ↔ Node)

退出阶段前,在 commit message 或 PR 描述里显式列出这 5/6 项各自怎么过的(具体口令 + 实际输出)。

<gate_evidence_few_shot>

**正面样例(具体口令 + 实际输出)**:

```
1. 代码到位:grep -rn 'def insert_history' app/services/  → app/services/record_service.py:127 (1 hit)
2. 单测绿:pytest tests/unit/test_record_service.py -q → 12 passed, exit 0
3. 集成测:pytest tests/integration/test_record_api.py -q → 8 passed, exit 0
4. 手工 smoke:curl -X POST :8000/api/v1/records -d '{"name":"X"}' → 201 + DB 落库 verified by SELECT
5. grep 防回归:grep -rn 'old_status_name' app/  → 0 hits
```

**反面样例(等价于未过)**:

```
1. 代码到位:应该都写了
2. 单测绿:测试都跑过
3. 集成测:本地没起 DB,后面再补
4. 手工 smoke:逻辑应该没问题
5. grep 防回归:没扫
```

</gate_evidence_few_shot>

---

### B. 文档型验收门(5 项)

适用阶段:SKILL.md 步骤 1(demo 文档化)+ 步骤 2(plan 设计)+ 步骤 3(review)+ 步骤 4(拆 IMPLEMENTATION)+ 步骤 7(文档体系)— 所有产物为 markdown 的阶段。

| 项 | 通过标准 | 实际口令样例 |
|---|---|---|
| **1. 产物文件齐备** | plan / WORKFLOW 指明的 .md 文件全部存在,路径准确 | `ls -la docs/*.md`;`grep '<期望文件>' -l` |
| **2. 反向重建测** | 独立 agent(L1)只读文档反推业务/设计/流程,与原 demo / plan 对照,差异 ≤ `doc_recon_diff_threshold` | agent 输出 diff 报告;人工核对差异条目数 |
| **3. 5 个典型查询走通** | 列出 5 个 query("X 字段在哪里定义?""Y 函数怎么调用?")→ 期望命中段,实跑核验 | `grep -nE '<query 关键词>' docs/*.md` 命中期望段 |
| **4. 链接 / 章节号 grep** | 所有相对链接路径可解析;章节号无断号 | `grep -nE '\]\(' docs/*.md` 每条目验路径存在;`grep -nE '^## [0-9]+\.' plan.md` 序号连续 |
| **5. 源代码行数偏差** | 仅适用复制泛化场景(如七维 review 整体复制),偏差 < `loc_drift_threshold` | `wc -l <src> <dst>`;diff <10% |

**第 2 项"差异 ≤ N"算法**:
- 列出原 demo / plan 的业务流程节点总数(角色 + 状态机节点 + 主路径节点)
- N = 节点总数 × 10% 向上取整,最小 1
- 差异 = (反推流程节点) Δ (原节点) 的对称差大小

---

## §1 单阶段章节模板

每个阶段(§X0 / §X1 / ...)独立成章,固定结构:

```markdown
## §X<N> 阶段 N — <名称>

**验收门类型**:代码型 5/6 项  /  文档型 5 项(必标其一)

### §X<N>.1 目标
- 一句话目标(可验证)
- 进入本阶段的前置依赖:阶段 X<N-1> 验收门全过 + ...

### §X<N>.2 步骤(实施期实际执行)
1. <子步骤 1>(命令样例)
2. <子步骤 2>
...

### §X<N>.3 关键交付
- `<文件路径>`:<函数/类清单>
- ...

### §X<N>.4 验收门(逐项口令)
| 项 | 实际口令 | 期望输出 |
|---|---|---|
| 1. 代码到位 | `grep -rn 'def X' app/` | 命中 ≥1 |
| 2. 单测绿 | `pytest tests/unit/test_X.py -q` | 退出码 0 |
| ... | ... | ... |

### §X<N>.5 反问钩子(开头)
- <问题 1,yes/no + 可计数 + 可 grep>
- <问题 2,...>

### §X<N>.6 三层 review(末尾)
- L0 人工:用户读 §X<N>.4 验收门实际证据 + 修订点
- L1 agent(prompt 用 `review-agent-prompt.md` XML 6 槽位填):
  - 角色定位:实施者反向(或其他视角)
  - 必读:本阶段产物 + 主 plan + IMPLEMENTATION 本章节
  - 输出:Phase A finding(coverage 优先,带 confidence)
- L2 sanity-scan(修订后):扫修订漂移

### §X<N>.7 commit 准备
- staged 文件清单:...
- 提示用户:"本阶段已 staged,可 commit"
- commit message 由用户撰写(prefix 参考 §1.5)
```

---

## §1.5 commit prefix 参考约定

每阶段 `commit_per_stage` 个 commit(默认 1-3);commit message 由用户撰写;以下前缀**参考**(由用户决定是否采用):

- `feat(<阶段号>): <子目标>` — 新功能
- `test(<阶段号>): <子目标>` — 测试
- `docs(<阶段号>): <子目标>` — 文档
- `chore(<阶段号>): <子目标>` — 工程性
- `fix(<阶段号>): <子目标>` — bug 修复
- `refactor(<阶段号>): <子目标>` — 重构

<commit_mechanism>

**Commit 拦截机制(单约束,settings.json hook)**:

实际拦截发生在 `.claude/settings.json` 的 PreToolUse hook,拦截 AI 主动调用以下命令(用户主动调用不拦截):
```
git commit / git commit --amend / git tag -a / git rebase -i
gh pr merge / git merge --no-ff / git push
```

本文档不再复述 prompt 层"AI 不自动 commit"约束 — hook 是唯一可靠层,prompt 重复声明反而引入冗余。

</commit_mechanism>

---

## §1.6 三轨制 + PROGRESS 四象限职责

|  | 过程态(滚动写) | 结论态(归档) |
|---|---|---|
| **当前态** | **`LOG.md`** — 排错过程 / 临时修法 | **`PROGRESS.md`** — 当前阶段状态 / 产物索引 / 唤醒指针 |
| **历史态** | — | **`NOTES.md`**(决策/修订/补充)+ **`TODO.md`**(V2 backlog)|

边界规则:
- 同一事件最多两处出现,跨处用 `详见 X §Y` 指针引用,内容不复制
- NOTES:`[局部修订]` vs `[路线级修订]` 必须明示;路线级标 `IMPLEMENTATION 是否同步重拆`
- LOG:与 NOTES 不重复;只记排错细节(命令 / 错误信息 / 临时修法)
- TODO:V2 / 上线后 backlog,按 P1/P2 优先级分组
- PROGRESS:每阶段末尾 + 每对话结束前 + 阻塞 + 中段反问触发时更新;`> stale_warmup_milestone_days` 必读里程碑层

---

## §1.7 阶段编号约定

- 多模块项目:`<模块前缀>X`,如 `API0` / `UI0` / `CLI0` / `ETL0`
- 单模块项目:可纯数字(`0` / `1` / ...)或保留单字母前缀(`S0` / `M0`),任选其一并在阶段全景表标注
- 新增阶段:在已发布阶段间插入号(如 `X3.5`)会让历史 commit 失联,推荐往末尾追加(`X13`)或拆分(`X3a / X3b`)并在 NOTES 说明

---

## §2 NOTES → plan + IMPLEMENTATION 反向同步

实施期发现 plan 与代码不一致时:

- **[局部修订]**(单字段 / 单签名漂移):仅 NOTES 记录,标 `Fixed in <plan §章节>`;plan + IMPLEMENTATION 可暂不改
- **[路线级修订]**(技术栈 / 架构 / 数据模型反向):
  - plan 文件原地改(主 plan)
  - IMPLEMENTATION-<模块>.md 同步重拆(影响阶段重置验收门)
  - 回到 SKILL.md 步骤 3 重跑七维 review(优先走局部 review 轻量分支,只跑受影响 pass)
  - 回环 ≤ `loop_max_rounds`,超出触发 L0 拍板(选项 A/B/C,见 review-output-template §3.5)
- **触发回写 batch**:NOTES ≥ `notes_writeback_trigger` 或 路线级修订 → 停下来跑 NOTES → plan + IMPLEMENTATION 批量回写 + 重启七维 review
- PROGRESS.md §1 包含 `NOTES 未回写计数 / 上次回写日期 / 是否触发 IMPLEMENTATION 改`

---

## §3 范例(本项目实操)

本项目用 SX(后端 S0-S12)+ FX(前端 F0-F12)阶段编号(多模块前缀),实际见:
- `archive/plans/IMPLEMENTATION-backend.md`
- `archive/plans/IMPLEMENTATION-frontend.md`
