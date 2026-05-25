# 修订后强制扫描清单(6 步)

> **何时跑**:每次完成 plan 修订后立即跑;不依赖记忆。
> **元层认知**:沉淀反模式到方法论 ≠ 自动应用。每次修订时即使知道反模式,仍可能踩同样的坑(典型场景:加 `within(card)` 时只改 .spec 内部代码、忘补顶部 import;改 §6.1 401 拦截器代码、忘改 §10.3 文字描述)。**每次完成 plan 修订后,立即把以下清单作为固定 checklist 跑一遍**,不要依赖"我记得方法论里讲过"。
> **配套**:与 [`../review-output-template.md`](../review-output-template.md) `<revision_scan_6_steps>` 同义,本文件是 Pass 7 触发时的就近副本。

---

<revision_scan_6_steps>

## Step 1 — import 完整性扫描(对应 Pass 3 强约束)

对每段刚改过的示例代码块:

```bash
# 1.1 找出本轮所有改过的示例代码块(看本轮 diff)
# 1.2 对每段 diff 涉及的代码块,**对照正文用到的每个标识符**反查顶部 import 段
# 1.3 任何"代码用了但 import 没列"或"代码删了但 import 仍在"都立刻补/删
```

常见漏点速查:
- `within` / `useMemo` / `useState` / `forwardRef` / `useImperativeHandle` / `useEffect`(React)
- `ApiError` / `isApiError`(自定义)
- `Button` / `Skeleton` / `Pagination`(shadcn)
- `dayjs` / `clsx` / `cva`(库)
- `apiClient` / `queryKeys` / `queryKeyPrefix`(项目)

## Step 2 — 跨章节引用对齐扫描(对应 Pass 6 强约束)

对本轮改过的每个被引用对象(hook 签名 / store 字段 / 组件 props / 字段类型),**grep 全部出现处**,逐处比对:

```bash
# 2.1 hook 签名:grep "useXxx(" plans/*.md — 数量 / 顺序 / 类型必须逐字一致
# 2.2 组件 props:grep "<Xxx" plans/*.md vs grep "interface XxxProps" — 字段集对齐
# 2.3 文字描述 vs 代码:grep 描述性段落里对代码的引用是否与最新代码一致
#     (典型:401 拦截器代码已加过滤,文字段落仍是旧口径)
```

## Step 3 — 章节号 / 引用 / 目录树扫描(对应 Pass 7)

```bash
# 3.1 章节号连续:grep -nE '^## [0-9]+\.' plan.md — 看序号有无断号
# 3.2 内部引用对齐:grep -nE '详见 §[0-9]+' plan.md — 每处引用的章节号是否真存在
# 3.3 目录树同步:大改后 §6.2 文件树是否与新增文件 / 重命名文件一致
```

## Step 4 — 残留旧命名 / 旧示例 grep

对本轮改过的命名 / 模式,grep 全部 plan 文件,确保旧命名 0 残留:

```bash
# 4.1 重命名:grep '<旧名>' plans/*.md — 应只剩 contract 反例描述行
# 4.2 旧 props 模式 / 旧 import path / 旧 selector 命名 同上
```

## Step 5 — 反向回归 grep(本轮新引入的关键 token 都被采用)

```bash
# 5.1 新 helper / 新约束:grep '<新 token>' plans/*.md — 是否所有应用处都用了新写法
#     (典型:加 queryKeyPrefix helper 后,所有 hard-code 字符串都改用 helper 了吗?)
```

## Step 6 — 验证产出(强制)

每轮修订完毕,**至少跑一次以下 grep 输出 0 / 完整覆盖**:

```bash
# 6.1 旧 camelCase 标识符 0 残留(若本轮做过 snake_case 转换)
# 6.2 旧路径 / 旧 prefix 0 残留
# 6.3 修订点的 anchor(如 P0-X / P1-X 注释)出现次数 ≥1
# 6.4 修订涉及的所有跨文件 import / 引用都 grep 一遍
```

> **强约束**:这个清单**不允许跳过**。每轮修订完成最后,**显式列出**"上述 6 步逐项做了"或"哪步做了哪步跳过 + 为什么"。如果无法说清楚,默认重跑一遍。
>
> **反例**:用户要修 plan,直接 Edit 完就报"全部修完",不跑扫描清单 — 下一轮 AI / 自主 review 必然又找出 import 漂移 / 描述与代码不一致 / 旧命名残留等问题(过去 N 轮的实证数据:**几乎每一轮都有 1–2 项是修订引入的**)

</revision_scan_6_steps>
