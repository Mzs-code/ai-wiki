# Skill Creator — 技能创建器

> 官方仓库：<https://github.com/anthropics/skills/tree/main/skills/skill-creator>
> 
> 介绍资料: <https://mp.weixin.qq.com/s/vjMG8i7DwQ7R2B1C4AVQdA>
> 
> 介绍资料: <https://mp.weixin.qq.com/s/nRVVqPaGxWdNqNrUcurSXg>

## 简介

`skill-creator` 是 Claude Code 官方提供的一个**元技能（meta-skill）**，用于创建、改进和评估其他 skill。你可以把它理解为"制作技能的技能"——帮助你为 Claude Code 开发自定义插件/命令，并通过迭代测试不断优化。

---

## 核心工作流程

整个过程是一个**迭代循环**：

```
确定意图 → 编写 SKILL.md → 生成测试用例 → 运行测试 → 评估结果 → 改进 skill → 重复
```

### 1. 确定意图（Capture Intent）

首先明确你的 skill 要做什么：

- 这个 skill 让 Claude 能做什么？
- 什么时候应该触发？（用户的哪些表达/场景）
- 期望的输出格式是什么？
- 是否需要设置测试用例来验证？

### 2. 访谈与调研（Interview and Research）

主动询问边界情况、输入输出格式、示例文件、成功标准和依赖项。在确认清楚之前不要急着写测试 prompt。

### 3. 编写 SKILL.md

SKILL.md 是 skill 的核心定义文件，包含：

- **name**：技能标识符
- **description**：触发条件和功能描述（这是触发 skill 的主要机制）
- **正文**：Markdown 格式的详细指令

### 4. 创建测试用例

编写 2-3 个真实的测试 prompt，保存到 `evals/evals.json`：

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "用户的任务提示",
      "expected_output": "预期结果描述",
      "files": []
    }
  ]
}
```

### 5. 运行与评估

对每个测试用例同时启动两个子任务：

- **有 skill 的运行**：加载 skill 后执行任务
- **基线运行**：不加载 skill（新建场景）或使用旧版 skill（改进场景）

运行完成后：

1. **打分（Grade）**：评估每个断言是否通过
2. **聚合（Aggregate）**：生成 benchmark 报告（通过率、耗时、token 用量）
3. **分析（Analyze）**：发现统计数据可能隐藏的模式
4. **启动查看器（Viewer）**：在浏览器中展示定性输出和定量数据

### 6. 迭代改进

根据用户反馈修改 skill，然后重新运行测试，直到：

- 用户满意
- 反馈全部为空（一切正常）
- 不再有实质性进展

### 7. 描述优化（Description Optimization）

优化 SKILL.md 中的 `description` 字段以提高触发准确率：

1. 生成 20 个触发评估查询（应触发 + 不应触发各 8-10 个）
2. 用户审核评估集
3. 运行优化循环（自动拆分训练集/测试集，迭代改进描述）
4. 应用最佳描述

### 8. 打包

```bash
python -m scripts.package_skill <path/to/skill-folder>
```

将 skill 打包成 `.skill` 文件供安装使用。

---

## Skill 目录结构

```
skill-name/
├── SKILL.md          # 必需：技能定义（YAML frontmatter + Markdown 指令）
├── scripts/          # 可选：可执行脚本（确定性/重复性任务）
├── references/       # 可选：按需加载的参考文档
└── assets/           # 可选：模板、图标、字体等资源
```

---

## 三级加载机制（Progressive Disclosure）

| 层级 | 内容 | 加载时机 | 建议大小 |
|------|------|----------|----------|
| 1 | name + description | 始终在上下文中 | ~100 词 |
| 2 | SKILL.md 正文 | skill 触发时加载 | < 500 行 |
| 3 | 捆绑资源（scripts/references/assets） | 按需加载 | 不限 |

---

## 使用方式

在 Claude Code 对话中直接描述你的需求，例如：

- `"我想创建一个 skill 来自动生成 commit message"`
- `"帮我改进我的 code-review skill"`
- `"对我的 skill 跑一下 benchmark"`

Claude 会自动识别并触发 `skill-creator`，引导你完成整个流程。

---

## 编写 Skill 的最佳实践

### 描述要"积极"

description 是触发 skill 的唯一入口。Claude 目前倾向于"少触发"，因此描述应该写得稍微"积极"一些。

**不好的写法：**
> 用于构建简单的数据仪表盘。

**好的写法：**
> 用于构建简单的数据仪表盘。当用户提到仪表盘、数据可视化、内部指标，或者想要展示任何类型的数据时，都应使用此 skill，即使他们没有明确说"仪表盘"。

### 用"解释为什么"代替"强制要求"

避免过多使用 `ALWAYS` / `NEVER`。尝试解释背后的原因，让模型理解**为什么**要这样做，而不是死记硬背指令。

### 避免过拟合

测试用例只是少量样本，skill 需要泛化到各种场景。不要为了让特定测试通过而加入过于狭窄的规则。

### 测试用例要真实

模拟用户实际会输入的内容：

**不好的测试：** `"格式化数据"` / `"从 PDF 提取文本"`

**好的测试：** `"我老板刚发了个 xlsx 文件（在下载目录里，好像叫 'Q4 sales final FINAL v2.xlsx'），她让我加一列利润率百分比，收入在 C 列，成本在 D 列"`

### 保持精简

SKILL.md 正文控制在 500 行以内。超出的内容放到 `references/` 目录，在 SKILL.md 中给出清晰的指引。大型参考文件（> 300 行）应包含目录。

### 多领域组织

当 skill 支持多个领域/框架时，按变体组织参考文件：

```
cloud-deploy/
├── SKILL.md              # 工作流 + 选择逻辑
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

Claude 只读取相关的参考文件。

---

## 注意事项

1. **description 是触发的关键** — 所有"何时使用"的信息都放在 description 中，不要放在正文里
2. **描述优化依赖 CLI** — `run_loop.py` 使用 `claude -p` 命令，仅在 Claude Code 环境中可用
3. **不要包含恶意内容** — skill 不能包含恶意软件、漏洞利用代码或安全威胁
4. **Claude.ai 上功能有限** — 无子任务并行、无浏览器查看器、无描述优化
5. **量化评估并非总是必要** — 主观类 skill（写作风格、设计质量）更适合定性评估
6. **关注重复模式** — 如果多个测试中子任务都独立写了类似的辅助脚本，说明应该将其捆绑到 skill 的 `scripts/` 目录中
