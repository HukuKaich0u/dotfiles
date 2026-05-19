# mise Guide

`mise` は runtime manager です。`node` `go` `java` みたいな言語やツールの version をそろえて、shell から使えるようにします。

このガイドでは、まず一般的な使い方を押さえて、そのあとでこの repo の `nix + Home Manager + mise` 構成でどう使うかをまとめます。

## まず何をすればいいか

普段は `mise` コマンドを毎回打つ必要はありません。`mise` が shell に入っていれば、普通に `node` や `go` をそのまま打って使います。

```sh
node --version
go version
java -version
```

`mise` を直接使うのは、主に次のときです。

- 今どの version が選ばれているか確認したい
- その場だけ特定 version で 1 コマンド実行したい
- project ごとに使う version を固定したい

## よく使うコマンド

### `mise current`

今のディレクトリで、どの tool のどの version が選ばれているか確認します。

```sh
mise current
```

「今この project では何が有効なのか」を見る基本コマンドです。

### `mise ls`

インストール済み version の一覧を見ます。

```sh
mise ls
```

「何がもう入っているか」を確認したいときに使います。

### `mise which <tool>`

今使われる実体の path を見ます。

```sh
mise which node
mise which go
```

PATH でどれが解決されているか怪しいときに便利です。

### `mise exec <tool>@<version> -- <command>`

その場だけ特定 version で 1 コマンド実行します。global 設定や project 設定を一時的に上書きしたいときに使います。

```sh
mise exec node@24 -- node --version
mise exec go@1.26 -- go version
```

普段の shell 全体を切り替えるというより、「この 1 回だけこれで実行したい」という用途です。

### `mise use <tool>@<version>`

project に入って、その project で使う version を固定したいときに使います。通常は `mise.toml` が作られるか更新されます。

```sh
mise use node@24
mise use go@1.26
```

repo に `mise.toml` を置くと、その project に入ったときにその version が優先されます。

### `mise install`

`mise.toml` などに書かれた version を実際にインストールします。

```sh
mise install
```

project 側で `mise.toml` を用意したあとに使う基本コマンドです。

## project ごとに version を固定したいとき

典型的な流れはこれです。

1. project root で `mise use node@24` のように指定する
2. 必要なら `mise.toml` の内容を確認する
3. `mise install` で必要 version を入れる
4. `mise current` で解決結果を確認する

たとえば Node.js project ならこうです。

```sh
mise use node@24
mise install
mise current
node --version
```

Go や Java でも同じ考え方です。

## この repo ではどうなっているか

この repo では、global runtime の source of truth は [nix/modules/home/programs/mise.nix](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/nix/modules/home/programs/mise.nix) です。`mise` 自体は `nix` / Home Manager で管理されています。

今の global runtime は次です。

- `bun = 1`
- `node = 24`
- `go = 1.26`
- `java = 25`
- `lua = 5.4`
- `terraform = 1.12`

つまり、この環境ではまず普通に次を打てば使える前提です。

```sh
bun --version
node --version
go version
java -version
lua -v
terraform version
```

zsh integration も有効なので、shell に入った時点で `mise` の解決結果が使われる構成です。

一方で、この repo では全部を `mise` に寄せていません。

- Python は global `mise` ではなく、project ごとに `uv` 中心で扱う前提
- Rust は `mise` ではなく `rustup` 中心で扱う前提

なので、この repo での理解は次の通りです。

- `mise` は `bun` `node` `go` `java` `lua` `terraform` の global runtime 層
- project ごとの細かい version 固定が必要なら `mise.toml` を使う
- Python と Rust はそれぞれ別の専用 tool に寄せる

## 迷ったらこれだけ覚えればよい

- 普段は `bun` `node` `go` `java` `lua` `terraform` をそのまま打つ
- 状態確認は `mise current`
- インストール済み一覧は `mise ls`
- 一時実行は `mise exec ... -- ...`
- project 固定は `mise use ...` と `mise install`
