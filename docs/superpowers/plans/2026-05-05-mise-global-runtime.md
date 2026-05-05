# mise Global Runtime Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Home Manager 管理の `mise` に global runtime として `node` `go` `java` を定義し、global config の source of truth を `.config/nix/home-manager/mise.nix` に固定する。

**Architecture:** `mise.nix` の `programs.mise.globalConfig.tools` を唯一の定義場所にし、`~/.config/mise/config.toml` は Home Manager 生成物として扱う。回帰テストは shell script で `mise.nix` の shape を確認し、`nix eval` と `home-manager build` で評価と生成物を検証する。

**Tech Stack:** Nix, Home Manager, shell regression test, mise

---

## Chunk 1: テストで global tools の shape を固定する

### Task 1: `mise.nix` に要求する global tools 定義を先にテスト化する

**Files:**
- Modify: `tests/mise_home_manager_bootstrap_test.sh`
- Check: `.config/nix/home-manager/mise.nix`

- [ ] **Step 1: failing test を追加する**

`tests/mise_home_manager_bootstrap_test.sh` に次の期待値を追加する。

```sh
assert_contains "$mise_nix" 'tools = {' \
  "mise.nix should manage global tools through config.toml"
assert_contains "$mise_nix" 'node = ' \
  "mise.nix should define a global node runtime"
assert_contains "$mise_nix" 'go = ' \
  "mise.nix should define a global go runtime"
assert_contains "$mise_nix" 'java = ' \
  "mise.nix should define a global java runtime"
```

- [ ] **Step 2: test が正しく fail することを確認する**

Run: `bash tests/mise_home_manager_bootstrap_test.sh`
Expected: FAIL with missing `node = `, `go = `, or `java = `

- [ ] **Step 3: failing test を commit する**

```bash
git add tests/mise_home_manager_bootstrap_test.sh
git commit -m "test: cover mise global runtimes"
```

## Chunk 2: `mise.nix` に global runtime を定義する

### Task 2: Home Manager 側の global tools を追加する

**Files:**
- Modify: `.config/nix/home-manager/mise.nix`
- Test: `tests/mise_home_manager_bootstrap_test.sh`

- [ ] **Step 1: minimal implementation を追加する**

`programs.mise.globalConfig.tools` を次の形にする。

```nix
programs.mise.globalConfig = {
  tools = {
    node = "<NODE_VERSION>";
    go = "<GO_VERSION>";
    java = "<JAVA_VERSION>";
  };
  settings = {};
};
```

`<NODE_VERSION>`, `<GO_VERSION>`, `<JAVA_VERSION>` は実際に採用する version へ置き換える。

- [ ] **Step 2: test を再実行して green を確認する**

Run: `bash tests/mise_home_manager_bootstrap_test.sh`
Expected: PASS

- [ ] **Step 3: globalConfig の評価結果を確認する**

Run: `nix eval --json .config/nix#homeConfigurations.KokiAoyagi.config.programs.mise.globalConfig`
Expected: JSON に `tools.node`, `tools.go`, `tools.java`, `settings` が含まれる

- [ ] **Step 4: Home Manager build を確認する**

Run: `home-manager build --flake .config/nix#KokiAoyagi`
Expected: PASS and new `result`

- [ ] **Step 5: 生成された config.toml を確認する**

Run: `sed -n '1,120p' result/home-files/.config/mise/config.toml`
Expected: `[tools]` に `node`, `go`, `java` が出力される

- [ ] **Step 6: wiring を commit する**

```bash
git add .config/nix/home-manager/mise.nix tests/mise_home_manager_bootstrap_test.sh
git commit -m "feat(nix): define global runtimes in mise"
```

## Chunk 3: live 環境への反映と動作確認

### Task 3: switch 後の shell から global runtime を確認する

**Files:**
- Modify: `.config/nix/home-manager/mise.nix`
- Verify: live shell state

- [ ] **Step 1: Home Manager を適用する**

Run: `home-manager switch --flake .config/nix#KokiAoyagi`
Expected: PASS

- [ ] **Step 2: `mise` が global tools を認識していることを確認する**

Run: `mise ls`
Expected: `node`, `go`, `java` が一覧に出る

- [ ] **Step 3: current version 解決を確認する**

Run: `mise current`
Expected: global default として `node`, `go`, `java` が解決される

- [ ] **Step 4: 各実行ファイルが shell から引けることを確認する**

Run: `node --version`
Expected: configured node version

Run: `go version`
Expected: configured go version

Run: `java -version`
Expected: configured java version

## Unresolved questions

- `node` の global default version は何にするか
- `go` の global default version は何にするか
- `java` の global default version は何にするか
