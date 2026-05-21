#!/usr/bin/env bash
# feishu-send-media.sh — Send an image or file to a Feishu chat
# Usage: ./feishu-send-media.sh <type> <file_path> <chat_id> <app_id> <app_secret>
#   type: "image" or "file"

set -e

TYPE="$1"
FILE_PATH="$2"
CHAT_ID="$3"
APP_ID="$4"
APP_SECRET="$5"

if [[ -z "$TYPE" || -z "$FILE_PATH" || -z "$CHAT_ID" || -z "$APP_ID" || -z "$APP_SECRET" ]]; then
  echo "Usage: $0 <image|file> <file_path> <chat_id> <app_id> <app_secret>"
  exit 1
fi

if [[ ! -f "$FILE_PATH" ]]; then
  echo "Error: File not found: $FILE_PATH"
  exit 1
fi

FILE_NAME=$(basename "$FILE_PATH")

# Step 1: Get tenant_access_token
echo "→ Getting token..."
TOKEN=$(curl -s -X POST 'https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal' \
  -H 'Content-Type: application/json' \
  -d "{\"app_id\":\"$APP_ID\",\"app_secret\":\"$APP_SECRET\"}" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); exit(1) if d['code']!=0 else print(d['tenant_access_token'])")

if [[ "$TYPE" == "image" ]]; then
  # Step 2a: Upload image
  echo "→ Uploading image..."
  KEY=$(curl -s -X POST 'https://open.feishu.cn/open-apis/im/v1/images' \
    -H "Authorization: Bearer $TOKEN" \
    -F 'image_type=message' \
    -F "image=@$FILE_PATH" \
    | python3 -c "import json,sys; d=json.load(sys.stdin); exit(1) if d['code']!=0 else print(d['data']['image_key'])")

  # Step 3a: Send image message
  echo "→ Sending image message..."
  CONTENT="{\\\"image_key\\\":\\\"$KEY\\\"}"
  MSG_TYPE="image"

elif [[ "$TYPE" == "file" ]]; then
  # Step 2b: Upload file
  echo "→ Uploading file..."
  KEY=$(curl -s -X POST 'https://open.feishu.cn/open-apis/im/v1/files' \
    -H "Authorization: Bearer $TOKEN" \
    -F 'file_type=stream' \
    -F "file_name=$FILE_NAME" \
    -F "file=@$FILE_PATH" \
    | python3 -c "import json,sys; d=json.load(sys.stdin); exit(1) if d['code']!=0 else print(d['data']['file_key'])")

  # Step 3b: Send file message
  echo "→ Sending file message..."
  CONTENT="{\\\"file_key\\\":\\\"$KEY\\\"}"
  MSG_TYPE="file"

else
  echo "Error: type must be 'image' or 'file'"
  exit 1
fi

RESULT=$(curl -s -X POST 'https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=chat_id' \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"receive_id\":\"$CHAT_ID\",\"msg_type\":\"$MSG_TYPE\",\"content\":\"$CONTENT\"}" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print('✓ Sent! message_id:', d['data']['message_id']) if d['code']==0 else print('✗ Failed:', d)")

echo "$RESULT"
