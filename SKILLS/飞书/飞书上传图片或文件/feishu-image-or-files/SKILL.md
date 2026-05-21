---
name: feishu-image-or-files
description: Send images or files to Feishu groups via official API. Use when user asks to send/upload to Feishu. Choose image type for: "发图片"/"send image"/"share screenshot". Choose file type for: "发文件"/"send file"/"以文件形式发送". When OpenClaw's message tool with media parameter fails, also use this skill.
---

# Feishu Image & File Upload

## Prerequisites
- Feishu bot with `im:resource` permission enabled
- Bot configured in `~/.openclaw/openclaw.json`

## Workflow

### Step 1: Get bot credentials

Use the helper script:

```bash
python3 scripts/get-bot-config.py <chat_id>
# Returns: {"account": "default", "app_id": "cli_xxx", "app_secret": "xxx"}
```

Or read `~/.openclaw/openclaw.json` directly — look under `messages.feishu.accounts` and match `groupAllowFrom` to the target `chat_id`.

### Step 2: Send image or file

Use the unified send script:

```bash
# Send as image (for image files)
bash scripts/feishu-send-media.sh image <image_path> <chat_id> <app_id> <app_secret>

# Send as file (for any file type)
bash scripts/feishu-send-media.sh file <file_path> <chat_id> <app_id> <app_secret>
```

### Manual API steps (if needed)

**For images:**

```bash
# 1. Get token
TOKEN=$(curl -s -X POST 'https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal' \
  -H 'Content-Type: application/json' \
  -d '{"app_id":"<appId>","app_secret":"<appSecret>"}' \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['tenant_access_token'])")

# 2. Upload image → get image_key
IMAGE_KEY=$(curl -s -X POST 'https://open.feishu.cn/open-apis/im/v1/images' \
  -H "Authorization: Bearer $TOKEN" \
  -F 'image_type=message' \
  -F 'image=@/path/to/image.png' \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['data']['image_key'])")

# 3. Send image message
curl -s -X POST 'https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=chat_id' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"receive_id\":\"<chat_id>\",\"msg_type\":\"image\",\"content\":\"{\\\"image_key\\\":\\\"$IMAGE_KEY\\\"}\"}"
```

**For files:**

```bash
# 1. Get token (same as above)

# 2. Upload file → get file_key
FILE_KEY=$(curl -s -X POST 'https://open.feishu.cn/open-apis/im/v1/files' \
  -H "Authorization: Bearer $TOKEN" \
  -F 'file_type=stream' \
  -F 'file_name=filename.ext' \
  -F 'file=@/path/to/file.ext' \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['data']['file_key'])")

# 3. Send file message
curl -s -X POST 'https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=chat_id' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"receive_id\":\"<chat_id>\",\"msg_type\":\"file\",\"content\":\"{\\\"file_key\\\":\\\"$FILE_KEY\\\"}\"}"
```

## Notes
- Token expires in ~2 hours — always fetch fresh
- **Image limits**: 10MB max; formats: JPEG, PNG, WEBP, GIF, TIFF, BMP, ICO
- **File limits**: 30MB max; any file type
- OpenClaw `message` tool `media` parameter is **unreliable** for Feishu — use this skill instead
