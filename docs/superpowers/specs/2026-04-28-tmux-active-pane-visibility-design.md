# tmux Active Pane Visibility 設計

**Goal:** 選択中 pane を、pane border の見た目だけで今より明確に判別できるようにする。

## 方針

- 変更対象は `.config/nix/home-manager/tmux/tmux.conf` の pane border style のみ
- active pane は高コントラスト色と `bold` を使って強調する
- inactive pane は現状維持か、必要最小限だけ落として差を広げる
- pane 本文、status line、popup、plugin 設定は変更しない

## 選択肢

### Option 1: active border だけ強くする

- 影響範囲が最小
- 見た目の癖が増えにくい

### Option 2: active / inactive の両方を調整する

- 差はさらに出る
- 変更量が少し増える

### Option 3: pane border status を有効にしてラベル帯を出す

- 最も判別しやすい
- 情報量が増え、レイアウト密度も変わる

## 採用

Option 1。

ユーザーが border のみ強調したいと指定したため、active border を目立つ色へ寄せ、`bold` を付けて最小差分で対応する。
