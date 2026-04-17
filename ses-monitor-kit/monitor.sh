#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
METRICS_FILE="$SCRIPT_DIR/current_metrics.txt"
CPU_COUNT=1
THRESHOLD_WA=80
THRESHOLD_LOAD=$(echo "$CPU_COUNT * 1.5" | bc)
THRESHOLD_MEM=90

if [ ! -f "$METRICS_FILE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M')] ERROR: $METRICS_FILE が見つかりません" >&2
    exit 1
fi

wa=$(grep "^wa=" "$METRICS_FILE" | cut -d= -f2)
load=$(grep "^load=" "$METRICS_FILE" | cut -d= -f2)
mem=$(grep "^mem_used_pct=" "$METRICS_FILE" | cut -d= -f2)

alerts=()

if (( $(echo "$wa > $THRESHOLD_WA" | bc -l) )); then
    alerts+=("CPU wait: ${wa}% (閾値: ${THRESHOLD_WA}%)")
fi

if (( $(echo "$load > $THRESHOLD_LOAD" | bc -l) )); then
    alerts+=("load average: ${load} (閾値: ${THRESHOLD_LOAD})")
fi

if (( $(echo "$mem > $THRESHOLD_MEM" | bc -l) )); then
    alerts+=("メモリ使用率: ${mem}% (閾値: ${THRESHOLD_MEM}%)")
fi

[ ${#alerts[@]} -eq 0 ] && exit 0

if [ -z "$DISCORD_WEBHOOK_URL" ] && [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

if [ -z "$DISCORD_WEBHOOK_URL" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M')] ERROR: DISCORD_WEBHOOK_URL が設定されていません" >&2
    exit 1
fi

timestamp=$(date '+%Y-%m-%d %H:%M')
message="🚨 異常検知 [${timestamp}]\n"
for alert in "${alerts[@]}"; do
    message+="${alert}\n"
done
message+="対象ホスト: WSL-demo"

curl -s -X POST "$DISCORD_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"$(echo -e "$message")\"}" \
    > /dev/null

echo "[$(date '+%Y-%m-%d %H:%M')] 異常検知 → Discord通知送信"
