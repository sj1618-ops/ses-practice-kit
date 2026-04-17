#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== SES Monitor Kit セットアップ ==="
echo ""

# Discord webhook URL の入力
echo "Discord webhook URLを入力してください："
echo "（取得方法: Discordのチャンネル設定 → 連携サービス → ウェブフック → 新しいウェブフック）"
echo ""
read -p "URL: " webhook_url

if [ -z "$webhook_url" ]; then
    echo "ERROR: URLが入力されていません"
    exit 1
fi

# .env に保存
echo "DISCORD_WEBHOOK_URL=$webhook_url" > "$SCRIPT_DIR/.env"
echo "✓ Discord URLを保存しました"

# cron登録（重複チェックあり）
CRON_CMD="* * * * * cd $SCRIPT_DIR && bash monitor.sh >> /tmp/ses-monitor.log 2>&1"

if crontab -l 2>/dev/null | grep -q "ses-monitor-kit"; then
    echo "✓ cronはすでに登録済みです"
else
    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
    echo "✓ cronに登録しました（毎分実行）"
fi

echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "次のコマンドで異常を再現できます："
echo ""
echo "  # 異常に切り替え（1分以内にDiscord通知が来ます）"
echo "  cp $SCRIPT_DIR/metrics/anomaly.txt $SCRIPT_DIR/current_metrics.txt"
echo ""
echo "  # 正常に戻す"
echo "  cp $SCRIPT_DIR/metrics/normal.txt $SCRIPT_DIR/current_metrics.txt"
echo ""
echo "  # cronログを見る"
echo "  tail -f /tmp/ses-monitor.log"
