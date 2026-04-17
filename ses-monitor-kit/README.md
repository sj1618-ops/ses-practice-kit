# SES Monitor Kit

WSL上で動かす、AI監視スクリプト体験キット。

「ファイルを差し替えたらDiscordに通知が来た」を1分で体験できる。

---

## 前提

- WSL（Ubuntu 22.04推奨）
- `curl` がインストール済み（`curl --version` で確認）
- Discordアカウントと通知を受け取るチャンネル

---

## セットアップ（1回だけ）

### 1. Discord webhook URLを取得する

1. Discordで通知を受け取りたいチャンネルを右クリック →「チャンネルの編集」
2. 「連携サービス」→「ウェブフック」→「新しいウェブフック」
3. 「ウェブフックURLをコピー」

### 2. setup.shを実行する

```bash
cd ses-monitor-kit
bash setup.sh
```

URLを貼り付けるとcronへの登録まで自動で終わる。

---

## 使い方

### 異常を再現する

```bash
cp metrics/anomaly.txt current_metrics.txt
```

1分以内にDiscordに通知が来る：

```
🚨 異常検知 [2026-04-17 10:42]
CPU wait: 95.2% (閾値: 80%)
load average: 3.87 (閾値: 1.5)
対象ホスト: WSL-demo
```

### 正常に戻す

```bash
cp metrics/normal.txt current_metrics.txt
```

次の実行タイミングから通知が来なくなる。

### ログを見る

```bash
tail -f /tmp/ses-monitor.log
```

---

## 後片付け（cronを削除する）

```bash
crontab -l | grep -v "ses-monitor-kit" | crontab -
```

---

## 仕組み

```
current_metrics.txt  ←  ここを差し替えるだけ
        ↓
  monitor.sh（毎分cronから実行）
        ↓
  閾値を超えていたら？
        ↓
  Discord webhook に通知
```

監視する指標と閾値：

| 指標 | 閾値 |
|------|------|
| CPU wait (wa%) | 80% 超 |
| load average | 1.5 超 |
| メモリ使用率 | 90% 超 |
