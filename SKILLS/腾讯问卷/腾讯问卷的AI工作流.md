# 用 Claude Code + 腾讯问卷 Skill 创建在线问卷的 AI 工作流

> 一份从「问卷内容设计」到「在线投放链接 + 跳转逻辑全配置」的全流程操作手册。
> 适用场景：中等以上复杂度的问卷（多分支、条件题、按选项跳题），且不希望开通腾讯问卷付费版。

---

## 0. 工作流总览

```
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│ 1. plan 模式打磨 │ -> │ 2. 安装腾讯问卷  │ -> │ 3. Skill 创建在线│ -> │ 4. curl 写入逻辑 │
│    问卷 Markdown │    │    Skill + Token │    │    问卷拿链接    │    │    跳转 / 条件题 │
└──────────────────┘    └──────────────────┘    └──────────────────┘    └──────────────────┘
        ↓                       ↓                       ↓                       ↓
    问卷.md                Skill 就绪          survey_id + hash          基础逻辑生效
```

四步结束后，问卷可以直接群发投放。

---

## 1. 用 Plan 模式打磨问卷内容

### 1.1 为什么不直接让 AI「一把生成」

问卷的本质是把分析目标拆成一组互不重叠、能加总成结论的题目。这件事**问题定义比措辞重要十倍**：题目顺序、必填/选填、跳转分支、量表锚点、选项穷尽性都是结构性的决策。一把生成出来的问卷，往往细节是对的、整体不咬合（比如 ROI 量化目标和题目映射不到位、追问没接到主题上）。

正确的做法是**进入 Claude Code 的 plan 模式**，先把目标和约束讲清楚，再让 AI 出方案，反复 review。

### 1.2 Plan 模式的进入方式

在 Claude Code 会话中：

- **快捷键**：`Shift+Tab` 在 `default` / `plan` / `auto` 三个模式之间循环，循环到 `plan`
- **斜杠命令**：直接在输入框里发 `/plan`（如果你的 Claude Code 版本支持）
- **由 Claude 触发**：当你描述了一个非平凡的实现任务，Claude 会主动用 `EnterPlanMode` 工具发起计划

进入 plan 模式后，Claude 只读不写，专注产出方案文件。你会在 UI 里看到一个高亮提示，确认进入。

### 1.3 第一轮 prompt 模板

```
我要做一份「<场景>」问卷，调研对象是「<人群>」，分析目标是「<目标>」。
约束：
- 预计填写时长 <N> 分钟
- 必须包含：<必须的题目/分组>
- 不能包含：<敏感字段或合规红线>
- 数据用途：<会怎么用>，是否挂钩绩效/考核
请进入 plan 模式，先输出问卷骨架（区块划分 + 每个区块的题数预算 + ROI/分析目标到题目的映射表），先不写题目。
```

骨架确认后再让它把题目写出来。**先骨架后题目**，否则改一次题目就要把跳转逻辑重画一次。

### 1.4 Review 的几个关键检查点

每轮迭代请它至少检查这些：

| 维度 | 检查问题 |
|---|---|
| **结构** | 区块划分是否互斥且穷尽？是否有跳转分支需要切走整段？ |
| **题型** | 单选 / 多选 / 量表 / 文本 用得是否合理？量表锚点（1=…、5=…、10=…）是否清晰？ |
| **必填** | 哪些必填、哪些选填？追问类（"请简述案例"）一律选填 |
| **分支** | 不同分支用户实际作答的题数是否平衡？是否会强迫某分支答其他分支的题？ |
| **量化** | 每个分析目标是否能映射到具体题目？ROI / 等效预算 / 满意度是否各有题支撑？ |
| **诚实度** | 是否有诱导性表述？是否给出"用得不多 / 不达预期"等真实反馈的出口？ |

### 1.5 Plan 模式的产物

应当是一份 **可执行的问卷设计文档**，包含至少：

- 卷首引导语（数据用途、是否挂绩效）
- 区块划分及跳转逻辑示意
- 每道题：标题、类型、选项、必填/选填、（可选）追问
- 卷尾感谢页
- 附录：题目结构总览、跳转逻辑、必填/选填分布、ROI 量化的题目映射

把它存成项目内的 markdown 文件，比如 `Claude-Code-投入产出问卷.md`，作为后续创建问卷的**唯一信源**。

---

## 2. 安装腾讯问卷 Skill

### 2.1 官方 Skill 开放平台注册

- [https://wj.qq.com/claw](https://wj.qq.com/claw)

### 2.2 一句话安装

在 Claude Code 会话里直接发：

```
请从 https://wj.gtimg.com/agent-skills/tencent-survey-skill-1.1.1.zip 下载该 zip 压缩包，完成解压后，协助安装包内的 Skill，然后设置环境变量 TENCENT_SURVEY_KEY="wjpt_xxx"
```

---

## 3. 用 Skill 把问卷上线

把上一步沉淀的 markdown 交给 Claude Code，让它去调用 Skill。在会话里发：

```
针对 Claude-Code-投入产出问卷.md 使用这个问卷skills 帮我创建问卷
```

### 3.1 创建成功

成功后会返回 `survey_id` 和 `hash`，你的问卷链接就是 `https://wj.qq.com/s2/{survey_id}/{hash}`。

Skill 中的 `update_logic` 需要升级为 VIP 版本才能用。如果未开通，调用时会返回 `api error [PermissionDenied]: paid_function_trial_no_permission`，可以走 §4.2 的 BFF 接口配置基础逻辑，或者引导用户开通高级版后再用。

### 3.2 三条最容易踩的坑

1. **段落说明只能用 `[段落说明]`**：`[文本描述题]` 在文档里被列为别名，但 `create_survey` 实际不接受，会整卷拒收。
2. **题目内部不能有空行**：标题与选项之间一旦插入空行，腾讯问卷会把它解析成两道题。题目之间用一个空行分隔即可。
3. **选项不要字母前缀**：写「满意」而不是「A. 满意」，否则字母会变成选项文字的一部分。

> 如果返回 `api error [InvalidArgument]: invalid_text_format`，几乎都是上述三条之一。先用一个**最小子集**（4-5 题）调通再扩展全文。

---

## 4. 配置问卷逻辑（跳转 / 条件显示）

### 4.1 在网页配置（最稳）

打开 `https://wj.qq.com/edit/v2?sid={survey_id}` → 「逻辑」按钮 → 添加规则。

腾讯问卷网页基础逻辑支持的动作：

- **显示 / 隐藏题目**（条件触发）
- **跳转**（选项级 goto / 题目级 goto / 跳到结束）

适合 5 条以内规则手点。**任何题目结构调整后，规则不会自动重建，需要重检。**

### 4.2 走网页 BFF 接口一次性写入

#### 4.2.1 从浏览器抓 cookie 与端点

1. 在浏览器使用 F12 打开开发者模式，进入 Network 标签页
2. 用网页编辑器**先手动配置一条最简单的规则**（比如"选 A 显示 B"）作为模板
3. 浏览器打开 DevTools → Network，点击保存
4. 找到对 `https://wj.qq.com/api/v2/surveys/{sid}/logic` 的 POST 请求，右键 → Copy as cURL
5. 发给 Claude Code，让它帮你完成之前未完成的逻辑配置

#### 4.2.2 几条经验

- **cookie 会过期**（几小时到几天），所以这条路适合一次性批量写入，不适合长期自动化
- **这是网页 BFF 私有接口**，腾讯改前端时可能改路径或加 CSRF / 签名校验，今天能用不代表明天能用
- **写完务必在网页编辑器刷新一遍并预览答卷**，确认每个分支的题目数量、跳转目标、条件显示符合预期
- **题目级跳题（goto）和 survey_rules 是两个体系**：本接口只动 `survey_rules`；如果你需要"选了 A 直接跳到第 N 题"风格，仍然要走网页或题目级 goto

### 4.3 备选：付费版的 update_logic

如果团队已经开通腾讯问卷高级版，可以走 OpenAPI：

```bash
mcporter call tencent-survey.update_logic --args '{
  "survey_id": 26503449,
  "dsl": "if `q-5-37e4::o-101-74ce` or `q-5-37e4::o-102-847b` then show `q-6-d15e`"
}'
```

DSL 语法详见 Skill 自带的 `references/update_logic.md`，支持条件 / 跳转 / 替换 / 随机抽题等。**写的是 `survey_dsl` 字段，跟 `survey_rules` 互不影响**，两套规则会同时生效（执行顺序：基础逻辑先、自定义逻辑后）。

未开通时调用会返回 `api error [PermissionDenied]: paid_function_trial_no_permission`。

---

## 5. 故障排查速查表

| 现象 | 原因 | 处理 |
|---|---|---|
| `create_survey` 返回 `invalid_text_format` | DSL 用了 `[文本描述题]` / 题内有空行 / 选项带字母前缀 | 改用 `[段落说明]` / 删空行 / 去前缀。先用 4-5 题最小子集排查 |
| `update_question` 返回 `survey_not_editable` | 问卷处于回收中 | 先在网页暂停回收，再编辑 |
| `update_logic` 返回 `paid_function_trial_no_permission` | 自定义逻辑是付费功能 | 走 §4.2 BFF 接口 / §4.1 网页配置，或开通高级版 |
| BFF `/logic` POST 返回 401 / 鉴权错误 | cookie 过期或 X-Answer-Session 不匹配 | 重新登录浏览器，重抓 cookie |
| BFF `/logic` POST 返回 200 但规则没生效 | payload 里 `rule` 字段未做 stringify（直接传了对象） | 必须 `jq --rawfile` 把内层 JSON 当字符串塞进去 |
| Skill 工具不在 `mcporter list` 里 | mcporter 未安装 / Token 未写入 | 重做 §2.2，看 setup.sh 输出是否 `READY` |

---

## 6. 附录：本流程涉及的关键资源

- 腾讯问卷 Skill 入口与 Token 管理：[https://wj.qq.com/claw](https://wj.qq.com/claw)
- Skill ZIP：`https://wj.gtimg.com/agent-skills/tencent-survey-skill-1.1.1.zip`
- MCP endpoint：`https://wj.qq.com/api/v2/mcp`
- 网页 BFF endpoint（非公开）：`https://wj.qq.com/api/v2/surveys/{sid}/logic`
- Skill 内置参考文档：`~/.claude/skills/tencent-survey/references/`（`create_survey.md` / `update_logic.md` / `update_question.md` / `auth.md` 等）

---

## 7. 写在最后

整套流程里**真正自动化的部分**是 §3（创建问卷）和 §4.3（如果你开通了付费版）。§4.2 的 BFF 接口走的是网页内部 API，能跑但不稳定，定位是**一次性批量写入的快捷方式**，不要把它沉淀成长期脚本。如果你团队会持续做问卷，建议要么吃下网页配规则的成本，要么开通付费版让 `update_logic` 接管。
