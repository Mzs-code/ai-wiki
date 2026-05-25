#!/usr/bin/env bash
# check_cache_age.sh
# 检查 references/best-practices.md 的 last_fetched 是否超过 cache_ttl_days(默认 30 天)
# 输出: STATUS=fresh|stale|missing  AGE_DAYS=<N>  LAST_FETCHED=<YYYY-MM-DD>
# 退出码: 0=fresh, 1=stale, 2=missing/parse-error

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE="${SCRIPT_DIR}/../references/best-practices.md"
TTL_DEFAULT=30

if [[ ! -f "$CACHE" ]]; then
  echo "STATUS=missing AGE_DAYS=- LAST_FETCHED=-"
  exit 2
fi

LAST_FETCHED=$(grep -m1 'last_fetched:' "$CACHE" | sed -E 's/.*last_fetched:[[:space:]]*([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/')
TTL=$(grep -m1 'cache_ttl_days:' "$CACHE" | sed -E 's/.*cache_ttl_days:[[:space:]]*([0-9]+).*/\1/')
TTL="${TTL:-$TTL_DEFAULT}"

if [[ -z "$LAST_FETCHED" ]]; then
  echo "STATUS=missing AGE_DAYS=- LAST_FETCHED=-"
  exit 2
fi

# 计算天数差(macOS / Linux 兼容)
if date -j -f "%Y-%m-%d" "$LAST_FETCHED" "+%s" >/dev/null 2>&1; then
  FETCHED_TS=$(date -j -f "%Y-%m-%d" "$LAST_FETCHED" "+%s")
else
  FETCHED_TS=$(date -d "$LAST_FETCHED" "+%s")
fi
NOW_TS=$(date "+%s")
AGE_DAYS=$(( (NOW_TS - FETCHED_TS) / 86400 ))

if (( AGE_DAYS > TTL )); then
  echo "STATUS=stale AGE_DAYS=$AGE_DAYS LAST_FETCHED=$LAST_FETCHED TTL_DAYS=$TTL"
  exit 1
else
  echo "STATUS=fresh AGE_DAYS=$AGE_DAYS LAST_FETCHED=$LAST_FETCHED TTL_DAYS=$TTL"
  exit 0
fi
