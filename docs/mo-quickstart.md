# mo クイックスタート

[`mo`](https://github.com/k1LoW/mo) は、Markdown をブラウザで確認するための軽いビューアです。  
ここでは、普段使いする最小限のコマンドだけを載せます。

## インストール

```bash
brew install k1LoW/tap/mo
```

## まず使うコマンド

### 1 ファイルを開く

```bash
mo README.md
```

いちばん基本の使い方です。  
ファイルを保存すると、ブラウザ表示も更新されます。

### ディレクトリごと開く

```bash
mo docs/
```

`docs/` 配下の Markdown をまとめて見たい時に使います。

### 監視しながら使う

```bash
mo --watch 'docs/**/*.md'
```

Markdown を監視して、対象ファイルを自動でセッションに追加します。  
複数ファイルを行き来しながら書く時はこれが便利です。

### 状態を確認する

```bash
mo --status
```

今どの `mo` サーバーが動いているか、どのファイルや watch パターンが登録されているかを確認できます。

### 終了する

```bash
mo --shutdown
```

デフォルトポートの `mo` サーバーを停止します。  
別ポートで動かしている場合は、たとえば次のようにします。

```bash
mo --shutdown -p 6276
```

## 迷ったらこの使い方

普段はこの 3 つを覚えておけば十分です。

```bash
mo README.md
mo docs/
mo --shutdown
```

## 実用メモ

- `mo` は通常 `http://localhost:6275` で動きます。
- Mermaid 図もブラウザ上で表示できます。
- `mo --status` で動作中のセッションを確認できます。
- `mo --shutdown` で止められます。

## 最初の確認

このリポジトリなら、まずは次で試せます。

```bash
mo docs/zsh-config-overview.md
```

Mermaid 図を含む Markdown が正しく表示されれば、普段使いする準備はできています。
