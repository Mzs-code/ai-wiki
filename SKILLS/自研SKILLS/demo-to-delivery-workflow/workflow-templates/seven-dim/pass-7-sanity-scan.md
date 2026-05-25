# Pass 7 — 大改后 sanity scan

> **触发**:reviewer 跑七维 review 的 Pass 7 时 Read 本文件;**任何修订完成后强制 Read** [`revision-scan-checklist.md`](revision-scan-checklist.md)。
> **上游**:[`../seven-dim-review.md`](../seven-dim-review.md) `<core_summary>`

---

<pass_7_sanity_scan>

如果本轮已经做了大改(批量替换、字段重命名、章节剥离、注脚清理),最后必须再扫一遍:

- 大改前的旧注释 / 旧示例 / 旧引用是否清干净
- 新约定是否在所有相关位置都贯彻(grep 关键 token 验证)
- 新引入的字段 / 函数 / 子类 是否在所有调用点都被采用
- 大改后**目录结构 / 索引列表 / 文件清单**是否与新增模块同步(典型疏漏:新增 router / service 文件后忘记更新顶部 §1.1 目录树)
- **技术栈依赖版本号锁定**(来源:前端 plan 七维 review 2026-05-09 P0-12 / P0-14 / P1-16):大改 / 切栈后必扫每个 dep 是否锁了主版本号 — `Tailwind v3 → v4`(CSS-first 配置形态切换)/ `react-router-dom v6 → v7`(`future.v7_*` 默认开 + `useNavigation` 默认 idle 等行为差异)/ `Zustand v4 → v5`(`StateCreator` 泛型签名 + `create()()` 双调用推荐)/ React 18 → 19 等都有**破坏性更新**;技术栈表 / package list **不能只写裸名字**(`zustand` / `tailwindcss`),必须带版本约束(`zustand: ^4.5.0` / `tailwindcss: ^3.4.0` / `react-router-dom: ^6.21.0`);否则实施者 npm install 默认拿下一主版本 → 第一次跑 dev server 就因配置形态不对失效(典型:Tailwind 旧 `tailwind.config.ts` 形态在 v4 不生效,所有样式失踪)
- **async / await 字面 grep**:`grep -n "^async def "` 列出所有 async 函数名,反查每处调用是否带 `await` 前缀(典型漏点:helper 由同步升级为 async 后,部分 caller 没同步加 `await`;`update_record` / `rollback_*` 这类循环内调用最容易漏)
- **修订引入的 import 漂移**:任何对示例代码块的修订(改 hook 实现 / 加新示例 / 切换 derive 模式 / 删原 useQuery 调用)都可能在顶部 import 段留下"未使用 import"或"未补 import"。**修订完毕必须把每段示例代码当成新代码重跑一次 Pass 3 的 import 完整性扫描** — 修订前的 review 通过≠修订后的代码可编译。常见漏点:
  - 删 hook 调用后 `import { useQuery }` / `import dayjs` 等仍在,但已未使用(Lint warning,留下死 import 让实施者困惑)
  - 加新示例代码块用了 `ApiError` / `Button` / `useMemo` / `useState` 等,但只改了正文没补 import(实施者照抄 → TS NameError)
  - 改 props 模式(组件 props → store-driven),旧 `interface XxxProps` 留下没删,造成"组件签名两份不一致" → 实施者按旧 interface 写出另一套组件(典型回归:HistoryDialog props vs store-driven 漂移)
- **修订引入的章节漂移**:大改后章节号断号 / 引用错位(如删 §12 后 §13 → §13.1 引用未更新);`grep -nE '^## [0-9]+\.|详见 §[0-9]+' plan.md` 验证编号连续 + 引用对得上
- **修订引入的契约漂移**:改了组件 props / hook 签名,但**测试文件、其它引用文件、文档示例**没同步;Pass 7 必须把所有跨文件引用(`grep <symbol> all-plans/*.md`)反查一遍

把整个 plan 当成"陌生人第一次读"再过一遍。

</pass_7_sanity_scan>
