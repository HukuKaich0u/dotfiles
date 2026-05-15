# Darwin Linux Home Manager Split Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep macOS on `nix-darwin`, add Linux standalone `home-manager`, and split Home Manager root into `shared` + OS wrappers.

**Architecture:** `nix/home-manager/shared.nix` owns common imports/packages/state. `nix/home-manager/darwin.nix` and `nix/home-manager/linux.nix` set only `home.username`, `home.homeDirectory`, and small OS-only deltas. `nix/nix-darwin/home_manager.nix` points at the darwin wrapper; `nix/flake.nix` exposes `darwinConfigurations."KokiAoyagi"` and `homeConfigurations."kokiaoyagi"`.

**Tech Stack:** Nix flakes, Home Manager, nix-darwin, shell tests

---

## Chunk 1: Red Tests

### Task 1: Repoint text-shape tests to the new root layout

**Files:**
- Modify: `tests/home_manager_only_flake_test.sh`
- Modify: `tests/nix_darwin_reset_test.sh`
- Modify: `tests/ghconfig_paths_test.sh`
- Modify: `tests/gitconfig_paths_test.sh`
- Modify: `tests/bacon_home_manager_migration_test.sh`
- Modify: `tests/mise_home_manager_bootstrap_test.sh`
- Modify: `tests/nvim_home_manager_migration_test.sh`
- Modify: `tests/tmux_nix_migration_test.sh`
- Modify: `tests/wezterm_home_manager_migration_test.sh`
- Modify: `tests/yazi_home_manager_migration_test.sh`
- Modify: `tests/zsh_nix_migration_test.sh`

- [ ] Replace `home_nix=nix/home-manager/home.nix` assertions with `shared_nix=nix/home-manager/shared.nix` where the test is checking common imports.
- [ ] In `tests/nvim_home_manager_migration_test.sh`, move `pngpaste` assertions from `shared.nix` to `darwin.nix`; keep cross-platform package assertions on `shared.nix`.
- [ ] In `tests/home_manager_only_flake_test.sh`, expect `homeConfigurations."kokiaoyagi"`, `./home-manager/linux.nix`, and keep darwin entry assertions.
- [ ] In `tests/nix_darwin_reset_test.sh`, expect `home-manager.users."KokiAoyagi" = ../home-manager/darwin.nix;`.
- [ ] Run:

```bash
sh tests/home_manager_only_flake_test.sh
sh tests/nix_darwin_reset_test.sh
sh tests/ghconfig_paths_test.sh
sh tests/nvim_home_manager_migration_test.sh
```

Expected: FAIL on missing `shared.nix` / wrapper wiring.

- [ ] Commit:

```bash
git add tests/home_manager_only_flake_test.sh tests/nix_darwin_reset_test.sh tests/ghconfig_paths_test.sh tests/gitconfig_paths_test.sh tests/bacon_home_manager_migration_test.sh tests/mise_home_manager_bootstrap_test.sh tests/nvim_home_manager_migration_test.sh tests/tmux_nix_migration_test.sh tests/wezterm_home_manager_migration_test.sh tests/yazi_home_manager_migration_test.sh tests/zsh_nix_migration_test.sh
git commit -m "test(nix): expect shared darwin linux split"
```

## Chunk 2: Shared + Wrappers

### Task 2: Split `home.nix` into common root and OS wrappers

**Files:**
- Create: `nix/home-manager/shared.nix`
- Create: `nix/home-manager/darwin.nix`
- Create: `nix/home-manager/linux.nix`
- Delete: `nix/home-manager/home.nix`

- [ ] Copy current `nix/home-manager/home.nix` body into `nix/home-manager/shared.nix`.
- [ ] Remove from `shared.nix`: `home.username`, `home.homeDirectory`, darwin-only local alias setup for `asciiImageConverter`, and `pngpaste` from `home.packages`.
- [ ] Keep in `shared.nix`: existing module imports, `home.stateVersion`, `home.sessionVariables`, common packages, `programs.home-manager.enable`.
- [ ] Create `nix/home-manager/darwin.nix`:

```nix
{
  pkgs,
  ...
}: {
  imports = [ ./shared.nix ];
  home.username = "KokiAoyagi";
  home.homeDirectory = "/Users/KokiAoyagi";
  home.packages = with pkgs; [ pngpaste pkgs."ascii-image-converter" ];
}
```

- [ ] Create `nix/home-manager/linux.nix`:

```nix
{
  ...
}: {
  imports = [ ./shared.nix ];
  home.username = "kokiaoyagi";
  home.homeDirectory = "/home/kokiaoyagi";
}
```

- [ ] Run:

```bash
sh tests/ghconfig_paths_test.sh
sh tests/gitconfig_paths_test.sh
sh tests/mise_home_manager_bootstrap_test.sh
sh tests/tmux_nix_migration_test.sh
sh tests/wezterm_home_manager_migration_test.sh
sh tests/yazi_home_manager_migration_test.sh
sh tests/zsh_nix_migration_test.sh
sh tests/nvim_home_manager_migration_test.sh
```

Expected: PASS.

- [ ] Commit:

```bash
git add nix/home-manager/shared.nix nix/home-manager/darwin.nix nix/home-manager/linux.nix nix/home-manager/home.nix
git commit -m "refactor(nix): split shared and platform home-manager roots"
```

## Chunk 3: Darwin + Linux Wiring

### Task 3: Rewire flake and darwin bridge

**Files:**
- Modify: `nix/flake.nix`
- Modify: `nix/nix-darwin/home_manager.nix`

- [ ] In `nix/flake.nix`, add a small helper:

```nix
mkPkgs = system: import nixpkgs {
  inherit system;
  config.allowUnfree = true;
  overlays = [ (import ./common/direnv-no-zsh-check-overlay.nix) ];
};
```

- [ ] Replace standalone entry `homeConfigurations."KokiAoyagi"` with Linux entry `homeConfigurations."kokiaoyagi"` using `system = "aarch64-linux"` unless evaluation proves another Linux target is required.
- [ ] Point Linux standalone Home Manager modules at `./home-manager/linux.nix`.
- [ ] Keep `darwinConfigurations."KokiAoyagi"` on `aarch64-darwin`; no machine-level change.
- [ ] In `nix/nix-darwin/home_manager.nix`, change only the user module target from `../home-manager/home.nix` to `../home-manager/darwin.nix`.
- [ ] Run:

```bash
sh tests/home_manager_only_flake_test.sh
sh tests/nix_darwin_reset_test.sh
sh tests/direnv_zsh_check_skip_test.sh
nix eval ./nix#darwinConfigurations.KokiAoyagi.system.primaryUser --raw
nix eval ./nix#homeConfigurations.kokiaoyagi.config.home.username --raw
```

Expected: shell tests PASS; eval prints `KokiAoyagi` and `kokiaoyagi`.

- [ ] Commit:

```bash
git add nix/flake.nix nix/nix-darwin/home_manager.nix
git commit -m "feat(nix): add linux standalone home-manager entry"
```

## Chunk 4: Final Verify

### Task 4: Fresh full check

**Files:**
- Check: `nix/flake.nix`
- Check: `nix/home-manager/shared.nix`
- Check: `nix/home-manager/darwin.nix`
- Check: `nix/home-manager/linux.nix`
- Check: `nix/nix-darwin/home_manager.nix`
- Check: `tests/*.sh`

- [ ] Audit hardcoded mac paths still inside shared config:

```bash
rg -n '/Users/KokiAoyagi|homeConfigurations\\."KokiAoyagi"|home-manager/home.nix' nix/home-manager nix/nix-darwin tests
```

Expected: no hits except darwin-only wrapper / darwin-only tests.

- [ ] Run full shell verification:

```bash
sh tests/home_manager_only_flake_test.sh
sh tests/nix_darwin_reset_test.sh
sh tests/ghconfig_paths_test.sh
sh tests/gitconfig_paths_test.sh
sh tests/bacon_home_manager_migration_test.sh
sh tests/mise_home_manager_bootstrap_test.sh
sh tests/nvim_home_manager_migration_test.sh
sh tests/tmux_nix_migration_test.sh
sh tests/wezterm_home_manager_migration_test.sh
sh tests/yazi_home_manager_migration_test.sh
sh tests/zsh_nix_migration_test.sh
sh tests/direnv_zsh_check_skip_test.sh
```

Expected: PASS.

- [ ] Optional stronger verification:

```bash
home-manager build --flake ./nix#kokiaoyagi
```

Expected: activation package builds.

- [ ] Commit:

```bash
git add nix/flake.nix nix/home-manager/shared.nix nix/home-manager/darwin.nix nix/home-manager/linux.nix nix/nix-darwin/home_manager.nix tests
git commit -m "test(nix): verify darwin and linux split"
```

## Unresolved Questions

- None.
