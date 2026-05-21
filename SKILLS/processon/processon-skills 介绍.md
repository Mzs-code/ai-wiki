# ProcessOn Skills 使用介绍

ProcessOn 官方出品的 Claude Code Skill，用一句自然语言生成可编辑的专业图形，包括流程图、泳道图、时序图、架构图、ER 图、组织结构图、时间轴、信息图等。

- 项目地址：https://github.com/processonai/processon-skills
- 在线编辑器：https://smart.processon.com/editor
- API Key 申请：https://smart.processon.com/user

---

## 使用流程

### 1. 申请 API 令牌

访问 https://smart.processon.com/user ，新建 API 令牌，格式为 `sk-po-xxxxxxxx`。

### 2. 下载 Skill 并导入 Claude Code

从 GitHub 克隆仓库，将 `skills/processon-diagram-generator` 放入 Claude Code 的 skills 目录（默认 `~/.claude/skills/`）。

或使用一键安装：

```bash
npx skills add https://github.com/processonai/processon-skills.git \
  --skill processon-diagram-generator -g -y
```

导入成功后，在 Claude Code 中输入 `/` 可看到 `processon-diagram-generator`。


### 3. 发起指令

示例指令：

> 帮我使用 /processon-diagram-generator 这个技能 生成一个登录注册流程图，要求布局清晰，适合产品和研发沟通
> 我的 apikey 是 sk-po-xxxx

Skill 会自动完成：语义分析 → Prompt 优化 → 流式生成 Mermaid DSL → 调用渲染服务输出图片。


---

## 产物

一次调用返回三份内容。

### DSL（Mermaid 源码）

````markdown
```mermaid
graph TD
    A([开始]) --> B[进入登录注册页]
    B --> C{是否已有账号？}
    C --> |否| D[输入手机号/邮箱]
    D --> E[前端格式校验]
    E --> F{格式校验通过？}
    F --> |是| G[发送验证码]
    G --> H[用户输入验证码]
    H --> I[后端校验验证码]
    I --> J{用户是否已存在？}
    J --> |否| K[写入用户数据库]
    K --> L[注册成功并自动登录]
    L --> M([结束])
    C --> |是| N[输入账号与密码]
    N --> O[前端非空校验]
    O --> P[调用后端鉴权接口]
    P --> Q[查询数据库并校验密码哈希]
    Q --> R{登录成功？}
    R --> |是| S[签发JWT Token并返回]
    S --> M
    R --> |否| T[返回错误提示并累计失败次数]
    T --> U{失败次数超阈值？}
    U --> |是| V[要求图形验证码]
    V --> N
    U --> |否| N
    F --> |否| W[提示格式错误]
    W --> D
    J --> |是| X[提示账号已存在]
    X --> D
```
````

纯文本，可入 Git、嵌文档、被其他工具二次解析。

### 在线编辑链接

```
https://smart.processon.com/editor
```

将 DSL 粘贴进去即可在 ProcessOn 画布上继续编辑样式、节点、泳道、配色。

<img width="2800" height="1632" alt="image" src="https://github.com/user-attachments/assets/77d06a3a-2176-4a5a-b0e3-954d37765c72" />

### 图片预览链接

直出 PNG 直链，可贴入 PRD、PPT、IM。

```
https://ai-smart.ks3-cn-beijing.ksyuncs.com/gallery/xxxxxxxx.png
```

<img width="2018" height="1642" alt="image" src="https://github.com/user-attachments/assets/90614f99-5e04-450d-b90c-975b20b46f58" />


---

## 补充说明

- 支持图类：流程图、泳道图、时序图、软件/云架构图、ER 图、组织结构图、时间轴、信息图、金字塔图、草图重绘。
- 仅生成 DSL、不渲染图片：命令行加 `--no-render`。
- API Key 建议使用环境变量 `PROCESSON_API_KEY` 保存，避免在对话中明文暴露。
- Skill 每次运行会自动比对版本，有新版本会提示更新。
