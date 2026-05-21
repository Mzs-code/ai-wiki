## feishu-image-or-files Skill 说明
### 功能
> 通过飞书官方 API 向飞书群发送图片或文件，解决 OpenClaw message 工具 media 参数在飞书渠道不可靠的问题。

文件结构

```
feishu-image-or-files/
├── SKILL.md
└── scripts/
    ├── get-bot-config.py      # 从 openclaw.json 读取 bot 配置
    └── feishu-send-media.sh   # 统一发送脚本（图片/文件）
```

### SKILL.md 要点

```
frontmatter description 同时覆盖图片和文件两种触发场景
流程分两条路径：image 用 /im/v1/images，file 用 /im/v1/files
消息类型对应：msg_type=image + image_key / msg_type=file + file_key
核心 API 流程
POST /auth/v3/tenant_access_token/internal → 获取 token
POST /im/v1/images（图片）或 POST /im/v1/files（文件）→ 获取 key
POST /im/v1/messages?receive_id_type=chat_id → 发送消息
前置条件
飞书机器人开启 im:resource 权限
OpenClaw 已配置飞书 bot（~/.openclaw/openclaw.json）
限制
图片：最大 10MB，支持 JPEG/PNG/WEBP/GIF/TIFF/BMP/ICO
文件：最大 30MB，任意类型
```

### 参考文档
> 上传图片：https://feishu.apifox.cn/api-9020999
> 
> 上传文件：https://feishu.apifox.cn/api-9020997
> 
> 获取 token：https://open.feishu.cn/document/server-docs/authentication-management/access-token/tenant_access_token_internal
