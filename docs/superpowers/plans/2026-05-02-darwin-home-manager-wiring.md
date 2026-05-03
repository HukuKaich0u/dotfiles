# darwin Home Manager Wiring Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `darwinConfigurations."KokiAoyagi"` to the flake while keeping `homeConfigurations."KokiAoyagi"` intact, and verify only the new wiring without applying it.

**Architecture:** Replace the old "home-manager only" regression test with a new wiring test that expects both flake entry points, then update `.config/nix/flake.nix` to expose a `nix-darwin` entry that imports the existing minimal `nix-darwin/configuration.nix`. Confirm the new and old entry points with text checks plus `nix eval`, and stop before any `darwin-rebuild` or `switch`.

**Tech Stack:** Nix, shell regression test, `nix eval`

---

## Chunk 1: Lock the dual-entry flake contract

### Task 1: Replace the old flake regression test with the new contract

**Files:**
- Modify: `tests/home_manager_only_flake_test.sh:1-40`
- Check: `.config/nix/flake.nix:1-34`
- Check: `.config/nix/nix-darwin/configuration.nix`

- [ ] **Step 1: Rewrite the regression test to expect both entry points**

```bash
#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
flake_nix="$repo_root/.config/nix/flake.nix"
darwin_config="$repo_root/.config/nix/nix-darwin/configuration.nix"

assert_contains() {
  file="$1"
  pattern="$2"
  message="$3"

  if ! grep -Fq "$pattern" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_contains "$flake_nix" 'homeConfigurations."KokiAoyagi"' \
  "flake should keep the standalone home-manager configuration"
assert_contains "$flake_nix" 'home-manager.lib.homeManagerConfiguration' \
  "flake should keep the home-manager builder"
assert_contains "$flake_nix" 'darwinConfigurations."KokiAoyagi"' \
  "flake should expose a nix-darwin configuration entry point"
assert_contains "$flake_nix" 'nix-darwin.lib.darwinSystem' \
  "flake should build the darwin configuration through nix-darwin.lib.darwinSystem"
assert_contains "$flake_nix" './nix-darwin/configuration.nix' \
  "flake should wire darwinConfigurations to nix-darwin/configuration.nix"
assert_contains "$darwin_config" './home_manager.nix' \
  "minimal nix-darwin config should keep importing home_manager.nix"

echo "darwin and home-manager flake wiring test passed"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/home_manager_only_flake_test.sh`  
Expected: FAIL because `flake.nix` does not expose `darwinConfigurations."KokiAoyagi"` yet

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/home_manager_only_flake_test.sh
git commit -m "test: cover darwin home-manager flake wiring"
```

## Chunk 2: Add the `darwinConfigurations` entry

### Task 2: Extend `flake.nix` without touching Home Manager modules

**Files:**
- Modify: `.config/nix/flake.nix:1-34`
- Check: `.config/nix/nix-darwin/configuration.nix`
- Check: `.config/nix/nix-darwin/home_manager.nix`
- Test: `tests/home_manager_only_flake_test.sh`

- [ ] **Step 1: Add `nix-darwin` to the outputs arguments and expose the new entry**

```nix
{
  description = "Home Manager configuration of KokiAoyagi";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    ...
  }: {
    homeConfigurations."KokiAoyagi" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
      };
      extraSpecialArgs = {inherit self;};
      modules = [
        ./home-manager/home.nix
      ];
    };

    darwinConfigurations."KokiAoyagi" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./nix-darwin/configuration.nix
      ];
    };
  };
}
```

- [ ] **Step 2: Re-run the wiring regression test**

Run: `bash tests/home_manager_only_flake_test.sh`  
Expected: PASS

- [ ] **Step 3: Verify the standalone Home Manager entry still evaluates**

Run: `nix eval .config/nix#homeConfigurations.KokiAoyagi.config.home.username --raw`  
Expected: `KokiAoyagi`

- [ ] **Step 4: Verify the darwin entry now evaluates**

Run: `nix eval .config/nix#darwinConfigurations.KokiAoyagi.system.primaryUser --raw`  
Expected: `KokiAoyagi`

- [ ] **Step 5: Verify only the intended files changed**

Run: `git diff -- .config/nix/flake.nix tests/home_manager_only_flake_test.sh`  
Expected: diff shows the new flake entry and the updated wiring test only

- [ ] **Step 6: Commit the wiring change**

```bash
git add .config/nix/flake.nix tests/home_manager_only_flake_test.sh
git commit -m "feat(nix): add darwin home-manager flake wiring"
```

Unresolved questions:
- None
