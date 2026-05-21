# 在 Claude Code 内使用 Codex 插件

OpenAI 官方插件：[openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc)

当前版本：**1.0.4**

通过本插件可以在 Claude Code（以下简称 cc）内直接调用 Codex（基于 GPT-5 系列），把调查、修复、代码审查等工作委托给 Codex，并复用 Codex CLI 已有的身份验证、配置、环境和 MCP 设置。

---

## 目录

- [安装](#安装)
- [命令一览](#命令一览)
- [典型工作流](#典型工作流)
- [常见操作](#常见操作)
  - [1. 下发任务 `/codex:rescue`](#1-下发任务-codexrescue)
  - [2. 状态检查 `/codex:status`](#2-状态检查-codexstatus)
  - [3. 代码审查 `/codex:review`](#3-代码审查-codexreview)
  - [4. 对抗式审查 `/codex:adversarial-review`](#4-对抗式审查-codexadversarial-review)
  - [5. 查询输出 `/codex:result`](#5-查询输出-codexresult)
  - [6. 取消任务 `/codex:cancel`](#6-取消任务-codexcancel)
- [已知问题与绕过方案](#已知问题与绕过方案)
- [工作原理](#工作原理)

---

## 安装

> 前提：已经安装 Claude Code 和 Codex CLI。

1. 在 cc 内添加插件市场：

   ```
   /plugin marketplace add openai/codex-plugin-cc
   ```

2. 安装插件：

   ```
   /plugin install codex@openai-codex
   ```

3. 重新加载插件：

   ```
   /reload-plugins
   ```

4. 首次运行检查：

   ```
   /codex:setup
   ```

---

## 命令一览

Codex 插件提供以下 7 个斜杠命令：

| 命令 | 功能 | 常用参数 |
|---|---|---|
| `/codex:setup` | 检查本地 Codex CLI 是否就绪；可选切换"停止时审查门"（review gate）开关；缺失时可引导 npm 安装 | `--enable-review-gate` / `--disable-review-gate` |
| `/codex:rescue` | 把调查、修复或延续性工作委托给 Codex rescue 子代理（即"让 Codex 来救场"） | `[--background\|--wait] [--resume\|--fresh] [--model <model\|spark>] [--effort <none\|minimal\|low\|medium\|high\|xhigh>]` |
| `/codex:review` | 让 Codex 对当前 git 工作区/分支做代码审查（**只读，不会改代码**） | `[--wait\|--background] [--base <ref>] [--scope auto\|working-tree\|branch]` |
| `/codex:adversarial-review` | "对抗式"审查：质疑实现思路、设计权衡、隐含假设，而不是只挑实现缺陷 | 同 `/codex:review`，可附加 `[focus ...]` |
| `/codex:status` | 列出当前仓库内活跃和最近完成的 Codex 任务，含 review gate 状态 | `[job-id] [--wait] [--timeout-ms <ms>] [--all]` |
| `/codex:cancel` | 取消正在后台运行的 Codex 任务 | `[job-id]` |
| `/codex:result` | 查看某个已完成 Codex 任务存储的最终完整输出 | `[job-id]` |

---

## 典型工作流

1. **环境就绪**：`/codex:setup` 一次性确认环境
2. **日常使用**：
   - `/codex:rescue` 让 Codex 做事
   - `/codex:review` 或 `/codex:adversarial-review` 让它做代码审查
3. **后台运行**：加 `--background`，然后用 `/codex:status` 查进度，`/codex:result <id>` 取结果，必要时 `/codex:cancel` 取消

---

## 常见操作

### 1. 下发任务 `/codex:rescue`

> - 可以使用命令，也可以直接使用自然语言。
> - 支持 `--background`、`--wait`、`--resume`、`--fresh`。
> - 如果未指定 `--resume` / `--fresh`，插件默认复用上一次的线程。
> - 如果不传递 `--model` 或 `--effort`，Codex 使用其默认值。

```
/codex:rescue <任务描述>
```

**示例**：

```
❯ 帮我问下 codex 它有什么模型

⏺ Bash(node "/Users/xxx/.claude/plugins/cache/openai-codex/codex/1.0.4/scripts/codex-companion.mjs" task
      "你这边有哪些可用模型？请列出所有可用的模型名称、对应的能力或定位（例如编码、推理、轻量等），以及默认模型是…)
  ⎿  [codex] Starting Codex task thread.
     [codex] Thread ready (019ddc22-f165-7621-8bf6-372333bb4099).
     [codex] Turn started (019ddc22-f1fd-7ac3-9488-5b740cd5a65f).
     … +24 lines (ctrl+o to expand)

⏺ Codex 那边的回答如下：
```

| 模型名称 | 定位 / 能力 |
|---|---|
| `gpt-5.5` | 前沿模型，适合复杂编码、深入研究、真实项目工作 |
| `gpt-5.4` | 强通用编码模型，适合日常开发任务 |
| `gpt-5.4-mini` | 小型、快速、成本较低，适合简单编码或轻量任务 |
| `gpt-5.3-codex` | 编码优化模型，适合代码实现、修复、重构等 |
| `gpt-5.2` | 面向专业工作的模型，适合长任务、复杂分析和持续型代理工作 |

> **默认模型**：沿用当前 Codex 会话的父模型，未显式指定时不会切换。
>
> **推理强度**：`low` / `medium`（默认）/ `high` / `xhigh`。

---

### 2. 状态检查 `/codex:status`

```
/codex:status
/codex:status task-abc123
```

**无任务时**：

```
⏺ ┌────────┬──────┬────────┬───────┬──────────┬───────────────────────────┬───────────┐
  │ Job ID │ Kind │ Status │ Phase │ Duration │          Summary          │ Follow-up │
  ├────────┼──────┼────────┼───────┼──────────┼───────────────────────────┼───────────┤
  │ (none) │ —    │ —      │ —     │ —        │ 本会话尚无 Codex 作业记录 │ —         │
  └────────┴──────┴────────┴───────┴──────────┴───────────────────────────┴───────────┘

  Session runtime: direct startup · Review gate: disabled
```

**有任务时**：

```
⏺ ┌─────────────────────┬───────┬──────────┬──────┬─────────┬─────────────┬────────────────────────────────────┐
  │       Job ID        │ Kind  │  Status  │ Phas │ Duratio │   Summary   │             Follow-up              │
  │                     │       │          │  e   │    n    │             │                                    │
  ├─────────────────────┼───────┼──────────┼──────┼─────────┼─────────────┼────────────────────────────────────┤
  │                     │       │          │      │         │ 我是        │                                    │
  │ task-moku34rw-ncdpn │ rescu │ complete │ done │ 10s     │ Codex，基于 │ codex resume 019ddc1a-ef90-7ce2-81 │
  │ d                   │ e     │ d        │      │         │  GPT-5 的编 │ 97-139985dd6bd7                    │
  │                     │       │          │      │         │ 码代理。    │                                    │
  └─────────────────────┴───────┴──────────┴──────┴─────────┴─────────────┴────────────────────────────────────┘
```

---

### 3. 代码审查 `/codex:review`

> - 此命令为**只读**命令，不会执行任何更改。
> - 在后台运行时，可使用 `/codex:status` 检查进度，使用 `/codex:cancel` 取消任务。

```
/codex:review
/codex:review --base main
/codex:review --background
```

---

### 4. 对抗式审查 `/codex:adversarial-review`

> 只读命令，不会修复代码。
>
> **使用场景**：
>
> - 发货前的审查不仅要关注代码细节，还要质疑设计方向。
> - 本次审查重点关注设计选择、权衡取舍、隐含假设和替代方法。
> - 针对特定风险领域（例如身份验证、数据丢失、回滚、竞争条件或可靠性）进行压力测试。

```
/codex:adversarial-review
/codex:adversarial-review --base main challenge whether this was the right caching and retry design
/codex:adversarial-review --background look for race conditions and question the chosen approach
```

---

### 5. 查询输出 `/codex:result`

> 同时会返回 Codex 的 session ID。

```
/codex:result
/codex:result task-abc123
```

---

### 6. 取消任务 `/codex:cancel`

```
/codex:cancel
/codex:cancel task-abc123
```

---

## 已知问题与绕过方案

### `/codex:rescue` 可能不会真正调用 Codex

**预期行为**：调用 `codex:codex-rescue` 子代理，由它去执行 companion 脚本与 Codex 交互。

**实际现象**：实测下来子代理并未真正转发请求，而是由 Claude 在当前会话内"自答"，并自称是 Claude 模型——显然不对。

**绕过方案**：直接用 Bash 调用 companion 脚本，跳过子代理这一层：

```bash
node "~/.claude/plugins/cache/openai-codex/codex/<version>/scripts/codex-companion.mjs" task "<原始请求>"
```

将 stdout 原样返回即可。

> 待官方插件修复后可移除该绕过方案。

---

## 工作原理

`codex-plugin-cc` 通过本地的 **Codex CLI** 和 **Codex app server** 进行中转，复用已有的 Codex 相同的本地身份验证、配置、环境和 MCP 设置。

**它不会启动一个独立运行时**，只是从 Claude Code 内部调用既有的 Codex 实例。
