# SKILLS — Claude Code 技能合集

本目录沉淀了围绕 **Claude Code Skills** 的实操经验,既包含 Anthropic 官方的「技能元工具」,也包含一份按官方最佳实践审查提示词的自研 skill,还有把第三方平台(ProcessOn / 腾讯问卷 / 飞书 / OpenAI Codex)接入 Claude Code 的踩坑全记录。

> **什么是 Skill?**
> Skill 是 Claude Code 的可插拔技能扩展,通过一个带 frontmatter 的 `SKILL.md` 描述「何时触发、怎么干」,Claude 在对话中按需自动调用。详见官方 [Skills 文档](https://docs.claude.com/zh-CN/docs/claude-code/skills)。

---

## 目录速览

| 分类 | 文档 | 你能学到什么 |
|------|------|------|
| 官方元技能 | [skill-creator](./官方SKILLS/skill-creator.md) | 用「制作技能的技能」从零编写、测试、迭代你自己的 Skill |
| 自研 skill | [review-by-claude-prompting-best-practices](./review-by-claude-prompting-best-practices/SKILL.md) | 按 Claude 官方 prompt engineering 最佳实践,自动对你写的 SKILL.md / system prompt 打分、改写、并发实测对比 |
| 第三方 Skill 案例 | [ProcessOn](./processon/processon-skills%20介绍.md) | 一句话生成流程图 / 时序图 / 架构图等可编辑专业图形 |
| 第三方 Skill 案例 | [腾讯问卷](./腾讯问卷/腾讯问卷的AI工作流.md) | 从「Plan 模式打磨问卷」到「拿到投放链接 + 配置跳转逻辑」的全工作流 |
| 第三方 Skill 案例 | [飞书 CLI (lark-cli)](./飞书/飞书cli/飞书%20CLI（lark-cli）使用记录.md) | 用 CLI 创建飞书文档、给群发消息,含 user / bot 双身份模型与坑位 |
| 第三方 Skill 案例 | [飞书 上传图片/文件](./飞书/飞书上传图片或文件/飞书上传图片或文件技能说明.md) | 用飞书官方 API 向群发送图片或文件,绕过 OpenClaw media 参数的不稳定 |
| 插件 | [Codex 插件 in CC](./Codex插件/codex-plugin-cc-guide.md) | 在 Claude Code 内调用 OpenAI Codex(GPT-5),做对抗式审查 / rescue / 状态检查 |

---

## 详细介绍

### 1. skill-creator —— 制作技能的技能

> 文件: [`官方SKILLS/skill-creator.md`](./官方SKILLS/skill-creator.md)
> 官方仓库: <https://github.com/anthropics/skills/tree/main/skills/skill-creator>

Anthropic 官方提供的**元技能**,帮你完成一个完整闭环:

```
确定意图 → 编写 SKILL.md → 生成测试用例 → 运行测试 → 评估结果 → 改进 skill → 重复
```

适合**第一次写自己的 skill**,或想把现有 skill 体系化升级的人。

---

### 2. review-by-claude-prompting-best-practices —— 提示词审查官

> 文件: [`review-by-claude-prompting-best-practices/SKILL.md`](./review-by-claude-prompting-best-practices/SKILL.md)
> 配套参考: [`references/best-practices.md`](./review-by-claude-prompting-best-practices/references/best-practices.md) · [`references/rubric.md`](./review-by-claude-prompting-best-practices/references/rubric.md)

按 Claude 官方 [prompt engineering 最佳实践](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/overview) 对任意提示词(SKILL.md / system prompt / agent 指令 / 普通 md)做**结构化审查**:

- **逐项打分**: 11 维 rubric, 90% 场景仅用浓缩 rubric 即可
- **生成 `.v2` 改进版**: 不覆盖原文件,留有对照
- **双 agent 并发实测**: 启动两个 Claude 同时跑新老版本同一任务,直接对比真实效果
- **30 天 TTL 缓存**: 官方文章会随新模型更新,避免拿过期规则审查

触发关键词: `审查这个 skill / 按最佳实践 review / 优化我的 prompt / audit this skill`

---

### 3. ProcessOn Skills —— 一句话出专业图

> 文件: [`processon/processon-skills 介绍.md`](./processon/processon-skills%20介绍.md)
> 项目地址: <https://github.com/processonai/processon-skills>

ProcessOn 官方出品的 Claude Code Skill,自然语言生成 **可编辑** 的:

流程图 · 泳道图 · 时序图 · 架构图 · ER 图 · 组织结构图 · 时间轴 · 信息图

API Key 形如 `sk-po-xxxxxxxx`,建议放 `PROCESSON_API_KEY` 环境变量。

---

### 4. 腾讯问卷 AI 工作流

> 文件: [`腾讯问卷/腾讯问卷的AI工作流.md`](./腾讯问卷/腾讯问卷的AI工作流.md)
> 配套作弊条: [`腾讯问卷/腾讯问卷-Skills-Cheatsheet.md`](./腾讯问卷/腾讯问卷-Skills-Cheatsheet.md)
> 投入产出问卷: [`腾讯问卷/Claude-Code-投入产出问卷.md`](./腾讯问卷/Claude-Code-投入产出问卷.md)

**适用场景**: 中等以上复杂度的问卷(多分支、条件题、按选项跳题),且不开通腾讯问卷付费版。

四步工作流:

```
1. plan 模式打磨问卷 Markdown
2. 安装腾讯问卷 Skill + 写入 Token
3. Skill 创建在线问卷,拿 survey_id + 链接
4. curl 写入跳转 / 条件题逻辑
```

Cheatsheet 里另外详细列出了 OpenAPI 路由树 vs BFF 鉴权的两套体系,以及 `claim_error / missing_token / NoRoute` 等错误码的根因与排查。

---

### 5. 飞书 CLI (lark-cli) 使用记录

> 文件: [`飞书/飞书cli/飞书 CLI（lark-cli）使用记录.md`](./飞书/飞书cli/飞书%20CLI（lark-cli）使用记录.md)
> 项目地址: <https://github.com/larksuite/cli>

一次完整的飞书 CLI 实操:**安装 → 应用配置 → 用户授权 → 创建文档 → 群发消息 → 维护**。

重点解释了飞书的 **user vs bot 双身份模型**:

| 身份 | 标识 | Token 类型 | 适用场景 |
|---|---|---|---|
| 用户 | `--as user` | user_access_token | 操作**你本人**的资源(个人云空间 / 日历 / 邮箱) |
| 应用 | `--as bot` | tenant_access_token | 应用级操作; 以**机器人名义**发消息 |

---

### 6. 飞书 上传图片/文件 Skill

> 文件: [`飞书/飞书上传图片或文件/飞书上传图片或文件技能说明.md`](./飞书/飞书上传图片或文件/飞书上传图片或文件技能说明.md)
> Skill 实现: [`飞书/飞书上传图片或文件/feishu-image-or-files/`](./飞书/飞书上传图片或文件/feishu-image-or-files/)

解决 **OpenClaw `message` 工具的 `media` 参数在飞书渠道不可靠**的问题。

走飞书官方三步 API:

```
POST /auth/v3/tenant_access_token/internal      → 拿 token
POST /im/v1/images  或  /im/v1/files            → 拿 image_key / file_key
POST /im/v1/messages?receive_id_type=chat_id    → 发送消息
```

Token ≈ 2 小时过期,脚本每次都重新获取,避免缓存踩坑。

---

### 7. Codex 插件 in Claude Code

> 文件: [`Codex插件/codex-plugin-cc-guide.md`](./Codex插件/codex-plugin-cc-guide.md)
> 项目地址: <https://github.com/openai/codex-plugin-cc>

OpenAI 官方插件,在 Claude Code 内**直接调用 Codex(GPT-5 系列)**,复用 Codex CLI 已有的身份验证、配置、MCP 设置。典型用法:

- `/codex:rescue` — 把卡住的任务委托给 Codex
- `/codex:review` — Codex 视角的代码审查
- `/codex:adversarial-review` — 对抗式审查,让两个模型互找毛病
- `/codex:status` — 状态检查

适合需要**多模型协同**的场景: Claude 主推,Codex 辅审。
