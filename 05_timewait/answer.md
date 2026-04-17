# 答え：TIME_WAITによるエフェメラルポートの枯渇

## どこを見るか

### ステップ1：リソース系は全部スルー

top・free・df — 全部正常。CPU・メモリ・ディスクに問題はない。  
ここで詰まるのが典型パターン。「リソースが正常 = 問題なし」ではない。

### ステップ2：netstat でTIME_WAITの数を確認

```
# netstat -an | grep -c TIME_WAIT
28547
```

28,547個のTIME_WAIT接続がある。

### ステップ3：ポートレンジと数を照合する

```
# /proc/sys/net/ipv4/ip_local_port_range
32768   60999
```

使えるポート番号の範囲: 32768〜60999 = **28,231個**。

TIME_WAITが28,547個 > 使えるポート数28,231個。  
**新しい接続を作るためのポート番号が枯渇している。**

### ステップ4：ss -s で全体像を確認

```
TCP: 28954 (estab 298, closed 28623, orphaned 8, timewait 28547)
```

アクティブな接続（estab）は298個だけ。  
ほぼ全部がTIME_WAIT（切断済みだが待機中）。

## TIME_WAITとは何か

TCP接続を切断した後、OSは一定時間（デフォルト60秒）そのポートを TIME_WAIT 状態で保持する。  
「遅れて届くパケット」を正しく処理するための安全機構。

このサーバーはAPIを頻繁に呼び出すため、接続→切断を毎秒何百回も繰り返していた。  
60秒 × 数百接続/秒 = 数万のTIME_WAITが溜まる。

## 解決の方向性

**即時：カーネルパラメータのチューニング**
```bash
# TIME_WAITソケットを素早く再利用する
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse

# ポートレンジを広げる
echo "1024 65535" > /proc/sys/net/ipv4/ip_local_port_range
```

**恒久設定（/etc/sysctl.conf）**
```
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535
```

**根本対応**
- HTTPの接続を都度切らずにHTTP Keep-Aliveで使い回す
- 外部APIへの接続プールを実装して接続数を制御する
- 頻繁に呼ぶAPIはHTTP/2（1本の接続で多重化）に切り替える
