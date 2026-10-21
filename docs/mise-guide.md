# Runtime 管理

常用の Node.js 24 / npm / pnpm は Nix で導入する。
`mise install` や対話 shell の hook がなくても通常の PATH で利用できる。
Node の patch version は `nix/flake.lock` の nixpkgs で固定する。

```sh
node --version
npm --version
pnpm --version
type -a node pnpm
```

## mise の担当

mise 自体と設定は Home Manager が管理し、macOS の zsh / Linux の Bash で有効にする。
global runtime の正本は `nix/modules/home/programs/mise.nix`。
導入時期による解決差をなくすため完全な version を記載する。

| Tool | Global version |
| --- | --- |
| Bun | 1.3.14 |
| Go | 1.26.6 |
| Java | 25.0.2 |
| Lua | 5.4.8 |
| Terraform | 1.12.2 |

Node は global mise config に置かない。Python は uv、Rust は rustup を使う。
version の固定は download artifact の hash 固定とは異なる。
project でより厳密な再現性が必要なら、その project の `mise.lock` も管理する。

## 初回導入 / 更新後

Home Manager を反映し、新しい shell を開いて repo root から実行する。

```sh
./scripts/common/setup-user.sh
mise current
mise ls
```

`setup-user.sh` は home directory を基準に global runtime を install する。
Node が 24 でなければ止まり、project override や古い PATH を確認できる。

旧設定が生成した `~/.local/bin/{pnpm,pnpx,yarn,yarnpkg}` のうち、mise Node の
Corepack を参照する symlink だけを Home Manager activation で外す。
pnpm は Nix 版を使用する。独自の executable / 他の管理元の symlink は保持する。
Yarn が必要な project は project 側で管理する。

## Project ごとの version

global Node は24でも、project の要件があれば mise の override を使える。
project の再現性を保つため、原則として完全な version を指定する。

```sh
mise use node@24.16.0
mise install
mise which node
```

他の project や project 外では通常の Nix 版 Node に戻る。
一時的な実行は `mise exec node@24.16.0 -- node --version`。
project の mise 設定 / lockfile は、その project で管理する。

## Runtime 更新

global runtime は `mise.nix` の完全な version を編集し、Home Manager を反映してから
`setup-user.sh` を実行する。`mise upgrade` だけでは repo の正本は更新されない。
Node 24 は nixpkgs / Home Manager / nix-darwin を一緒に更新し、build 後に反映する。
詳細は [Nix の更新・rollback](../nix/README.md#updating-inputs)。

Python project は `uv.lock` と Python version、Rust project は `rust-toolchain.toml` と
`Cargo.lock` を必要に応じて管理する。rust-analyzer / rustfmt / clippy と cross target も
Rust project の toolchain に合わせる。
