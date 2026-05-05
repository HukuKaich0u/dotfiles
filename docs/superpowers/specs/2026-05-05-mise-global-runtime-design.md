# mise Global Runtime 設計

**Goal:** Home Manager 管理の `mise` を、この Mac 全体で使う programming language / runtime の最小ランタイム層として定義し、global 設定と project ごとの環境定義の責務を分離する。

## スコープ

この設計は `mise` の global runtime 管理方針を定めることだけを対象にする。

含むもの:
- `.config/nix/home-manager/mise.nix` を global runtime の SoT とする方針
- `mise` が global に管理する対象 language / runtime の選定
- project ごとの `mise.toml`、Docker、`nix develop` / devShell との責務分担

含まないもの:
- 個別 runtime version の具体値決定
- 各 project repo への `mise.toml` 追加
- Dockerfile や devShell の具体的な修正
- Python package / virtualenv の管理方法変更

## 背景

`mise` 本体、`mise activate zsh`、`~/.config/mise/config.toml` の Home Manager 生成までは整った。一方で、どの language / runtime を `mise` に寄せるか、project ごとの環境定義を `mise.toml` と Docker / devShell のどちらに持たせるかは未整理である。

この repo では dotfiles / Home Manager 側に「マシン全体のデフォルト」を持ち、project 側には repo 固有の設定だけを置く方が構成として自然である。また、同じ runtime を複数の manager で二重管理すると version の source of truth が曖昧になる。

## 要件

- global runtime の source of truth は dotfiles repo 配下の `.config/nix/home-manager/mise.nix` に置く
- `mise` はマシン全体で素の shell から使いたい runtime だけを管理する
- Rust は `mise` に寄せず、引き続き `rustup` に任せる
- Python は global runtime として `mise` に寄せず、project 単位で `uv` 中心の運用を維持する
- project ごとの runtime version を `mise` で宣言したい場合は repo root の `mise.toml` を使う
- Docker や `nix develop` / devShell で環境を閉じる project では、それらを source of truth にしてよい

## 選択肢

### Option 1: global runtime を広く `mise` に寄せる

例:
- `python`
- `node`
- `go`
- `java`

Pros:
- runtime manager がほぼ `mise` に揃う
- shell から使う runtime を 1 箇所で定義しやすい

Cons:
- Python まで含めると `uv` と責務が近づきやすい
- Python project 側の流儀と global runtime の境界が曖昧になりやすい

### Option 2: Rust 以外をできるだけ `mise.toml` に統一し、global `mise` は薄くする

Pros:
- global config が最小で済む
- 各 project が独立して version を持てる

Cons:
- 新規 project 以外では素の shell に必要 runtime がない状態が起きやすい
- 「この Mac で普段使う runtime」の default がどこにもまとまらない

### Option 3: global `mise` は `node` `go` `java` に限定し、Python は `uv`、Rust は `rustup` に分離する

Pros:
- runtime manager の責務衝突が起きにくい
- よく使う runtime だけをグローバルに揃えられる
- Python / Rust は既存の専用ツールに寄せたままにできる

Cons:
- manager は複数残る
- Python だけ `mise` で揃わない

## 採用

Option 3。

`mise` は万能な manager として広げるより、「この Mac で常用する runtime を素の shell に供給する層」と割り切る方が明快である。Rust は ecosystem 全体が `rustup` 前提で揃っているため、そのまま残すのが自然である。Python は runtime version より project ごとの dependency / venv 管理が主問題になりやすく、`uv` を中心に据えた方が責務がはっきりする。

そのため、global `mise` の対象は `node` `go` `java` に限定する。Python は global `mise` に入れず、必要なら project ごとに `uv` と `mise.toml` または container / devShell のいずれかで扱う。

## 構成設計

### Global 層

`mise` の global source of truth は `.config/nix/home-manager/mise.nix` とする。

ここには次だけを置く。

- `programs.mise.enable`
- `programs.mise.enableZshIntegration`
- `programs.mise.globalConfig.settings`
- `programs.mise.globalConfig.tools`

`globalConfig.tools` に入れる対象は `node` `go` `java` だけとする。ここは「マシン全体で最低限いつでも使える runtime」を定義する場所であり、project 固有の version pin を持ち込まない。

### Project 層

project ごとに runtime version を `mise` で管理したい場合は、repo root に `mise.toml` を置く。

一方、Docker や `nix develop` / devShell によって実行環境を閉じる project では、それらを source of truth にしてよい。`mise.toml` は必須ではなく、project の運用モデルに合わせて選ぶ。

判断基準は次の通り。

- ローカル shell から直接 `node`, `go`, `java` を使うなら `mise.toml` を置く
- container / devShell の中だけで完結するなら、Dockerfile や devShell を source of truth にする

### Python 層

Python は global `mise` では管理しない。

project では次のどちらかを選ぶ。

- `uv` を中心に Python 環境を作る
- container / devShell の中で Python を閉じる

必要に応じて project の `mise.toml` に Python version を書くことは許容するが、それは global runtime の責務ではない。

## データフロー

1. Home Manager が `.config/nix/home-manager/mise.nix` を評価する
2. `programs.mise.globalConfig.tools` から `~/.config/mise/config.toml` が生成される
3. shell からは global default として `node`, `go`, `java` が使える
4. project に `mise.toml` がある場合は、その repo に入った時点で project 側の runtime 定義が優先される
5. project が Docker / devShell を source of truth にする場合は、runtime はその環境内で解決される

## エラーハンドリング / 衝突対策

- Rust を `mise` に入れないことで `rustup` との競合を避ける
- Python を global `mise` に入れないことで `uv` 主体の運用と衝突しにくくする
- global `mise` に project 固有 version を入れないことで、repo ごとの version pin が global config に漏れ出るのを防ぐ
- Docker / devShell を使う project では、runtime version の正本を 1 つに決める。`mise.toml` を置くなら Dockerfile / devShell はそれに追従させ、置かないなら `mise` 側で project version を持たない

## テスト方針

1. `home-manager build --flake .config/nix#KokiAoyagi` が通る
2. `result/home-files/.config/mise/config.toml` に `tools` セクションが生成される
3. `result/home-files/.config/zsh/.zshrc` に `mise activate zsh` が含まれる
4. global runtime を追加した後、`mise ls` または `mise current` で `node` `go` `java` の解決結果を確認する

## 成功条件

- global runtime の source of truth が `.config/nix/home-manager/mise.nix` に定まる
- global `mise` の対象が `node` `go` `java` に限定される
- Rust は `rustup`、Python は `uv` / project 環境に分離される
- project ごとに `mise.toml` と Docker / devShell のどちらを正本にするか判断できる
