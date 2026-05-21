# 腾讯问卷 Skills Cheatsheet

> 调用腾讯问卷 MCP Skill 时的事实型速查表。条目独立、可被检索/复用。
> 适用版本：tencent-survey-skill `1.1.1`
> 目标读者：下次接到类似任务的 AI / 工程师

---

## 0. 资源索引

| 资源 | URL / 路径 |
|---|---|
| Skill 入口 / Token 管理 | `https://wj.qq.com/claw` |
| Skill ZIP | `https://wj.gtimg.com/agent-skills/tencent-survey-skill-1.1.1.zip` |
| MCP endpoint (OpenAPI) | `https://wj.qq.com/api/v2/mcp` |
| BFF endpoint (非公开) | `https://wj.qq.com/api/v2/surveys/{sid}/logic` |
| 编辑器 URL | `https://wj.qq.com/edit/v2?sid={sid}` |
| 投放链接格式 | `https://wj.qq.com/s2/{sid}/{hash}` |
| Skill 内置 references | `~/.claude/skills/tencent-survey/references/` |
| mcporter 配置文件 | `~/.mcporter/mcporter.json` |
| Skill 安装目录 | `~/.claude/skills/tencent-survey/` |

---

## 1. 安装

```bash
# 1) mcporter
npm install -g mcporter

# 2) Skill 解压
mkdir -p ~/.claude/skills/tencent-survey \
  && curl -fsSL https://wj.gtimg.com/agent-skills/tencent-survey-skill-1.1.1.zip -o /tmp/tencent-survey-skill.zip \
  && unzip -o /tmp/tencent-survey-skill.zip -d ~/.claude/skills/tencent-survey \
  && chmod +x ~/.claude/skills/tencent-survey/setup.sh

# 3) 写 Token (注意环境变量名)
TENCENT_SURVEY_TOKEN="wjpt_xxx" \
  bash ~/.claude/skills/tencent-survey/setup.sh wj_check_and_start_auth
# 期望输出：READY
```

| 注意点 | 说明 |
|---|---|
| 环境变量名 | `setup.sh` 读取 `TENCENT_SURVEY_TOKEN`（不是 `TENCENT_SURVEY_KEY`） |
| Token 形态 | `wjpt_` 开头，70 字符；绑定单一团队 |
| 验证安装 | `mcporter list tencent-survey` → 应列 6 个 tool |

---

## 2. MCP 工具清单（6 个）

| 工具 | 写? | 幂等? | 主要参数 | 操作目标字段 |
|---|---|---|---|---|
| `check_skill_update` | 否 | 是 | `current_version` | — |
| `create_survey` | 写 | **否**（每次新建）| `text`, `scene?`, `project_id?` | 新问卷 |
| `get_survey` | 读 | 是 | `survey_id` | — |
| `update_question` | 写 | **否**（覆盖）| `survey_id`, `question_id`, `text` | 单题题目内容 |
| `update_logic` | 写 | **否**（覆盖）| `survey_id`, `dsl` | `survey_dsl`（**付费**）|
| `list_answers` | 读 | 是 | `survey_id`, `last_answer_id?`, `per_page?` | — |

**没有的工具**：删除问卷、删除题目、复制问卷、写 `survey_rules`（基础逻辑）、控制量表锚点、设题目级 goto、设选项级 goto。

---

## 3. DSL 语法（create_survey / update_question 共用）

### 3.1 基本结构

```
问卷标题            ← 仅 create_survey 第一行需要
引导语              ← 可选

区块说明[段落说明]

1. 题目标题[题型][必答|选答](描述)
选项A
选项B

=== 分页 ===
```

### 3.2 题型标签

| 你想要的 | DSL | 实测 type 字段 |
|---|---|---|
| 单选 | `[单选题]`（默认可省）| `radio` |
| 多选 | `[多选题]` | `checkbox` |
| 量表 1~N | `[量表题]` + 下行 `1~N` | **`star`**（见 §3.6）|
| 短文本 | `[单行文本题]` | `text` |
| 长文本 | `[多行文本题]` | `textarea` |
| 段落说明 | `[段落说明]` | `description` |
| 多项填空 | `[多项填空题]` + `____` | — |

### 3.3 三条强约束（违反则 `invalid_text_format` 拒收整卷）

1. **段落说明只能用 `[段落说明]`**
   文档把 `[文本描述题]` 列为别名，**实测整卷拒收**。
2. **题目内不能有空行**
   标题与选项之间一旦插入空行 → 解析为两道题。
3. **选项无字母前缀**
   写「满意」不是「A. 满意」。

### 3.4 描述（题下灰字）

DSL 末尾英文圆括号 `(...)` → 写入 `description` 字段。
title 内的中文括号 `（...）` 是 title 一部分，不会被解析。

```
请简述案例[多行文本题][选答](示例：独立完成原本不熟悉的技术栈模块)
```

### 3.5 选项填空（实证发现，文档未明示）

选项文字末尾加 4 个下划线 `____` → 该选项被前端渲染成「文字 + 输入框」。

```
其他____
```

服务端行为：
- 选项 `text` 字段被改写为 `其他____{fillblank-XXXX}`（XXXX 是 4 字符内部 ID）
- `enable_fillblank` 字段**仍是 `false`**（字段名违反直觉，忽略它）
- 前端识别 `{fillblank-XXX}` 标记自动渲染填空

文档把 `____` 描述为「多项填空题」专用，**实测对普通单选/多选选项同样有效**。

### 3.6 量表题 = `star` 类型，锚点不可控

DSL `[量表题]\n1~10` 实际生成：

```json
{ "type": "star", "starBeginNum": 1, "starNum": "10",
  "starShowCustomStart": "绝不可能",
  "starShowCustomEnd": "极有可能",
  "star_show_custom_middle": "中间" }
```

DSL 无控制锚点的语法。`update_question` 重写后锚点字段被保留为默认值。要改只能走网页或 BFF。

### 3.7 必答 / 选答

`[必答]` / `[选答]` 紧跟题型，控制 `required`。

### 3.8 富文本

| 语法 | 效果 |
|---|---|
| `**文本**` | 加粗 |
| `[文本](url)` | 链接 |
| `![alt](img){W,H}` | 图片（W/H 必填，可填 `auto`）|
| `!video(url)` | 视频（仅腾讯/B站/优酷）|

---

## 4. JSON 字段速查（get_survey 返回）

### 4.1 question 通用字段

| 字段 | DSL 控制 | 说明 |
|---|---|---|
| `id` | ❌ | `q-N-XXXX`，update_question 不变 |
| `title` | ✅ DSL 标题部分 | |
| `type` | ✅ `[题型]` | radio/checkbox/textarea/text/star/description |
| `required` | ✅ `[必答]` / `[选答]` | bool |
| `description` | ✅ DSL 末尾 `(...)` | 题下灰字 |
| `hidden` | ❌ | DSL 不控（默认 false）|
| `goto` | ❌ | 题目级跳转，DSL 不控 |
| `options` | ✅ 选项行 | 数组；ID 自动生成 |

### 4.2 option 字段

| 字段 | DSL 控制 | 说明 |
|---|---|---|
| `id` | ❌ | `o-N-XXXX`，**每次 update_question 重生成** |
| `text` | ✅ 选项文字 | 加 `____` 触发填空 |
| `enable_fillblank` | ⚠️ 不响应 DSL | 始终 false，忽略 |
| `goto` | ❌ | 选项级跳转，DSL 不控 |

### 4.3 量表 (`type: "star"`) 专属

| 字段 | 说明 | DSL 可控 |
|---|---|---|
| `starBeginNum` | 起始分（1~10 → 1）| 部分 |
| `starNum` | 分值数（10）| 部分 |
| `starShow` | 锚点风格（"可能性"）| ❌ |
| `starShowCustomStart` | 起点锚点文字 | ❌ |
| `starShowCustomEnd` | 终点锚点文字 | ❌ |
| `star_middle_num` | 中间值位置 | ❌ |
| `star_show_custom_middle` | 中点锚点文字 | ❌ |

---

## 5. update_question 行为（关键）

| 行为 | 影响 |
|---|---|
| 整题覆盖 | text 必须含完整一题（标题 + 类型 + 必答 + 描述 + 选项）|
| 题目 ID 不变 | 接口参数 `question_id` |
| **所有选项 ID 重新生成** | 引用具体选项 ID 的规则会失效 |
| 量表锚点字段保留 | `starShowCustomStart/End/middle` 不被 DSL 重置 |

**改动安全矩阵**（结合 `survey_rules`）：

| 改的题被规则如何引用 | update_question 安全? |
|---|---|
| 完全没被规则引用 | ✅ 安全 |
| 只被 `expects.objects` 引用题目 ID | ✅ 安全（题目 ID 不变）|
| 被 `condition.subjects` 引用具体选项 ID | ❌ 选项 ID 变化导致规则失效，需重写规则 |

---

## 6. 三套逻辑体系

| 体系 | 存储字段 | 写入路径 | 付费 | 适用 |
|---|---|---|---|---|
| **基础逻辑** | `survey_rules` | 网页编辑 ✅ / BFF `/logic` ✅ / OpenAPI ❌ | 免费 | 大多数条件显示/隐藏 |
| **自定义逻辑** | `survey_dsl` | `mcporter update_logic` | **付费** | 复杂表达式、跨题计算、随机抽题 |
| **题目级 goto** | `question.goto` / `option.goto` | 网页 | 免费 | "选 A 跳到第 N 题" |

两套规则可同时存在，执行顺序：基础逻辑 → 自定义逻辑。

---

## 7. update_logic（付费 / OpenAPI）

DSL 语法核心：

```
if `q-1-abcd::o-100-EFGH` then show `q-2-ijkl`
if `q-1-abcd::o-100-EFGH` or `q-1-abcd::o-100-IJKL` then show `q-2-mnop`
if `q-1-abcd::o-100-EFGH` then branch from `q-1-abcd` to END
if `q-1-abcd::o-100-EFGH` then hide `q-2-ijkl`,`q-3-qrst`
shuffle `q-1-abcd::o-100-A`~`q-1-abcd::o-100-D`
random show 1 from `q-1-abcd`~`q-3-qrst`
replace "XXX" in `q-3-qrst` title with `q-1-abcd`
```

| 关键字 | 说明 |
|---|---|
| `if ... then show/hide ...` | 条件显示/隐藏 |
| `branch from X to END` | 跳到结束 |
| `shuffle / random show` | 随机 |
| `replace ... with ...` | 内容替换 |
| ID 必须用反引号包裹 | `` `q-N-XXXX` `` |
| 多规则换行分隔 | JSON 中 `\n` |
| 整体覆盖 | 每次 POST 覆盖所有自定义逻辑 |

**未付费团队报错**：`api error [PermissionDenied]: paid_function_trial_no_permission`

---

## 8. BFF 写入 `survey_rules`（免费 / 非公开 API）

> ⚠️ 网页内部接口。今天能用不代表明天能用。腾讯改前端时可能改路径或加 CSRF/签名。**适合一次性批量写入，不要沉淀成长期脚本**。

### 8.1 端点

```
POST https://wj.qq.com/api/v2/surveys/{sid}/logic
```

`GET` 同 path 用 Bearer Token 返回 `404 NoRoute` —— 该路由**不在 OpenAPI 路由树**。

### 8.2 鉴权

**浏览器 session cookie**，不是 `wjpt_` Bearer Token。
两套鉴权完全独立，Bearer 触不到 BFF 路由。

抓 cookie 流程：
1. 浏览器登录腾讯问卷，进入编辑器
2. F12 → Network
3. 网页编辑器手动配一条规则保存
4. 找到对 `/logic` 的 POST 请求 → 右键 Copy as cURL
5. 提取 `Cookie` 整串 + `X-Answer-Session` header 的值

### 8.3 必需 header

```
Content-Type: application/json
Cookie: <整段>
X-Answer-Session: <cookie 中 answer_session= 后的值>
Origin: https://wj.qq.com
Referer: https://wj.qq.com/edit/v2?sid={sid}
```

### 8.4 Payload schema

```json
{ "rule": "<内层 JSON 的 stringify>" }
```

**注意**：`rule` 字段值是 JSON **字符串**，不是嵌套对象。必须 stringify。

内层 schema：

```json
{
  "model": [
    /* ConditionStatement... */
  ],
  "version": "3.0"
}
```

ConditionStatement schema：

```json
{
  "type": "ConditionStatement",
  "condition": [
    {
      "condition": {
        "subjects": ["q-N-XXXX::o-M-YYYY", "..."],
        "action": "selectOn",
        "operator": "&&"
      },
      "operator": "&&"
    }
  ],
  "expects": [
    { "action": "ShowAction", "objects": ["q-N-XXXX"] }
  ]
}
```

### 8.5 字段语义

| 字段 | 值 / 语义 |
|---|---|
| `condition[].condition.action` | `selectOn` = 选中即触发 |
| `condition[].condition.subjects` | 选项 ID 数组，单选题内多个选项 = OR 语义 |
| `condition[].condition.operator` | `&&`（多个 condition 之间是 AND）|
| `expects[].action` | `ShowAction`（默认隐藏 + 条件显示）/ `HideAction`（默认显示 + 条件隐藏）|
| `expects[].objects` | **题目 ID** 数组（不是选项！）|
| `model` 数组 | 整体覆盖。新 POST 完全替换旧 model |

### 8.6 ShowAction vs HideAction 语义

| Action | 语义 |
|---|---|
| `ShowAction` | 一旦某题被任何 ShowAction 引用为 object → 默认隐藏；条件触发后显示 |
| `HideAction` | 默认显示；条件触发后隐藏 |

### 8.7 成功响应

```json
{ "code": "OK", "data": {}, "status": 1, ... }
```

---

## 9. 错误码索引

| 错误码 | 来源 | 原因 | 处理 |
|---|---|---|---|
| `invalid_text_format` | create_survey / update_question | DSL 格式错（`[文本描述题]` / 题内空行 / 选项带字母前缀）| 改 DSL，先用 4-5 题最小子集排查 |
| `no_question_parsed` | update_question | text 为空或不含完整一题 | 检查 text |
| `unknown_question_type` | update_question | 不识别的 `[题型]` | 用 §3.2 列出的题型 |
| `survey_not_editable` | update_question / update_logic | 问卷在回收中 | 网页暂停回收 |
| `paid_function_trial_no_permission` | update_logic | 自定义逻辑是付费功能 | 走 §8 BFF / 网页 / 升级 |
| `claim_error` | 任何写操作 | 问卷不属于当前 Token 团队 | 检查 sid 与 Token 绑定 |
| `missing_token` / `invalid_token` / `token expired` | 任何调用 | Bearer Token 失效 | 重做 §1 第 3 步 |
| `NoRoute`（HTTP 404）| BFF endpoint + Bearer | OpenAPI 不暴露此路由 | 必须用 cookie 走 §8 |

---

## 10. 失踪能力（API 不暴露的事）

| 能力 | 替代路径 |
|---|---|
| 删除题目 | 网页编辑器 / BFF（抓网页删除请求复用）|
| 删除问卷 | 网页 |
| 复制问卷 | 网页 |
| 控制量表锚点 (`starShowCustomStart/End/middle`) | 网页 / BFF |
| 选项级 goto | 网页 / BFF |
| 题目级 goto | 网页 / BFF |
| 选项级 `enable_fillblank` 显式开关 | 用 DSL `____` 触发前端渲染（不依赖该字段）|
| 写 `survey_rules`（基础逻辑）| 网页 / BFF（§8）|
| 题目顺序调整 | 网页 / BFF（重排题目顺序的接口）|

---

## 11. 操作风险矩阵

| 操作 | 影响选项 ID | 影响题目 ID | 影响 `survey_rules` |
|---|---|---|---|
| `create_survey` | 全新 | 全新 | 清空 |
| `update_question` | **重生成该题选项** | 不变 | 若规则 subjects 引用此题选项 → 失效 |
| `update_logic` | 不影响 | 不影响 | 不影响（动 `survey_dsl`）|
| BFF POST `/logic` | 不影响 | 不影响 | **整体覆盖** |

---

## 12. 可复用代码片段

### 12.1 安全构造 update_question args（避免转义地狱）

```bash
SID=26503449
QID=q-16-1f34
DSL='13. 【C5】题目标题[多行文本题][选答]'

args=$(jq -n --arg sid "$SID" --arg qid "$QID" --arg text "$DSL" \
  '{survey_id: ($sid|tonumber), question_id: $qid, text: $text}')
mcporter call tencent-survey.update_question --args "$args"
```

### 12.2 批量给所有"其他"选项加填空

```bash
SID=26503449
mcporter call tencent-survey.get_survey --args "{\"survey_id\": $SID}" > /tmp/snap.json

build_dsl() {
  local qid=$1
  jq -r --arg qid "$qid" '
    .pages[].questions[] | select(.id == $qid) |
    (.title +
      "[" + (if .type == "checkbox" then "多选题"
             elif .type == "radio" then "单选题" else "?" end) + "]" +
      "[" + (if .required then "必答" else "选答" end) + "]" +
      (if (.description // "") != "" then "(" + .description + ")" else "" end)
    ) + "\n" +
    ([.options[].text | (if . == "其他" then "其他____" else . end)] | join("\n"))
  ' /tmp/snap.json
}

# 找出所有含「其他」选项的题
QIDS=$(jq -r '.pages[].questions[] | select(.options != null) |
              select(.options[].text == "其他") | .id' /tmp/snap.json)

for qid in $QIDS; do
  dsl=$(build_dsl "$qid")
  args=$(jq -n --arg sid "$SID" --arg qid "$qid" --arg text "$dsl" \
    '{survey_id: ($sid|tonumber), question_id: $qid, text: $text}')
  echo "=== $qid ==="
  mcporter call tencent-survey.update_question --args "$args"
done
```

### 12.3 BFF 写 `survey_rules`

```bash
SID=26503449

# Cookie 文件，权限 600
cat > /tmp/wj-cookie.txt <<'EOF'
<浏览器整段 cookie>
EOF
chmod 600 /tmp/wj-cookie.txt

# 内层 model JSON
jq -nc '{
  model: [
    {
      condition: [{ condition: { subjects: ["q-5-37e4::o-101-74ce"], action: "selectOn", operator: "&&" }, operator: "&&" }],
      expects:   [{ action: "ShowAction", objects: ["q-6-d15e"] }],
      type: "ConditionStatement"
    }
  ],
  version: "3.0"
}' > /tmp/wj-inner.json

# stringify 后包成外层 {"rule": "..."}
jq -nc --rawfile rule /tmp/wj-inner.json '{rule: $rule}' > /tmp/wj-payload.json

# POST
curl -sS -i -X POST "https://wj.qq.com/api/v2/surveys/$SID/logic" \
  -H "Content-Type: application/json" \
  -H "Origin: https://wj.qq.com" \
  -H "Referer: https://wj.qq.com/edit/v2?sid=$SID" \
  -H "X-Answer-Session: <cookie 里 answer_session 的值>" \
  -b "$(cat /tmp/wj-cookie.txt)" \
  --data @/tmp/wj-payload.json
# 期望返回 HTTP 200 + body 内 "code":"OK"

# 立刻清理
rm -f /tmp/wj-cookie.txt /tmp/wj-inner.json /tmp/wj-payload.json
```

### 12.4 验证规则数量与形态

```bash
mcporter call tencent-survey.get_survey --args "{\"survey_id\": $SID}" \
  | jq '.survey_rules.model | to_entries[] |
        "[\(.key+1)] \(.value.expects[0].action) \(.value.expects[0].objects | length) target(s) <- \(.value.condition[0].condition.subjects | length) subject(s)"'
```

### 12.5 查找所有题目和选项的 ID

```bash
# 所有题
jq -r '.pages[].questions[] | "\(.id) | \(.type) | \(.title | tostring | .[0:60])"' /tmp/snap.json

# 某题的所有选项
jq -r '.pages[].questions[] | select(.id == "q-3-2620") | .options[] | "\(.id) | \(.text)"' /tmp/snap.json
```

---

## 13. 典型工作流

### 13.1 创建 + 配规则（首次）

1. `create_survey` → 拿 `survey_id` / `hash`
2. `get_survey` → 列出题目和选项 ID
3. **规则路径选择**：
   - 简单 ≤5 条 → 网页编辑
   - 中等 → BFF（§8 + §12.3）
   - 复杂跨题 → 升级付费版用 `update_logic`
4. 验证（§12.4）+ 浏览器答卷预览

### 13.2 改题 + 不破规则

1. `get_survey` 拉当前结构
2. 检查待改题是否被 `condition.subjects` 引用具体选项 ID（§5 改动安全矩阵）
3. 安全的 → 直接 `update_question`
4. 危险的 → 改完后重新 BFF 写一次 `survey_rules`（cookie 复用或重抓）

### 13.3 批量同质改动（如所有"其他"加填空）

按 §12.2 模板：用 jq 自动构造 DSL，循环 update_question。
**前提**：要改的题都不被 `condition.subjects` 引用（否则规则失效）。

---

## 14. 决策速查

| 场景 | 路径 |
|---|---|
| 整卷格式问题排查 | 用 4-5 题最小子集试 create_survey |
| 单题大改 | update_question + 自动重生成选项 ID |
| 单题改 title 不动选项 | **做不到**，update_question 整题覆盖 |
| 加跳转 ≤5 条 | 网页 |
| 加跳转 >5 条 / 全自动化 | BFF (§8) 或付费 update_logic |
| 删题 | 网页 / BFF（无 API）|
| 量表锚点 | 网页 / BFF（DSL 不可控）|
| 选项加输入框 | DSL `选项文字____`（§3.5）|
