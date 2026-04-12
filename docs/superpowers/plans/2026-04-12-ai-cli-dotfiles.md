# AI CLI Dotfiles Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Codex と Claude Code の global 個人設定だけをこの dotfiles repo で管理できるようにし、stateful なローカルデータは管理対象から外したまま運用できるようにする

**Architecture:** repo 直下に `.codex/`, `.claude/`, `.agents/` を追加し、`install.sh` でそれぞれの managed file / directory を個別 symlink する。設定ファイルは sanitize した curated version を置き、`~/.codex` / `~/.claude` の mutable state とは共存させる。

**Tech Stack:** Bash, symlink-based dotfiles management, TOML, JSON, Markdown

---

## Chunk 1: Repo-managed AI config skeleton

### Task 1: Add managed directory structure

**Files:**
- Create: `.codex/AGENTS.md`
- Create: `.codex/config.toml`
- Create: `.claude/CLAUDE.md`
- Create: `.claude/settings.json`
- Create: `.agents/skills/.gitkeep`
- Create: `.claude/skills/.gitkeep`

- [ ] **Step 1: Create placeholder files and directories**

Create the exact repo layout below:

```text
.codex/
.claude/
.agents/skills/
.claude/skills/
```

- [ ] **Step 2: Add minimal Codex config**

Write `.codex/config.toml` with only curated portable settings:

```toml
model = "gpt-5.4"
model_reasoning_effort = "xhigh"
personality = "pragmatic"

[plugins."gmail@openai-curated"]
enabled = true
```

Expected: no `[projects.*]` entries remain.

- [ ] **Step 3: Add minimal Claude settings**

Write `.claude/settings.json` with only deliberate settings:

```json
{
  "model": "claude-opus-4-5-20251101",
  "alwaysThinkingEnabled": false
}
```

- [ ] **Step 4: Add global instruction file placeholders**

Create minimal initial versions:

```md
# .codex/AGENTS.md
Global personal defaults for Codex live here.
Project-specific policy belongs in each repository.
```

```md
# .claude/CLAUDE.md
Global personal defaults for Claude Code live here.
Project-specific policy belongs in each repository.
```

- [ ] **Step 5: Verify created files**

Run: `find .codex .claude .agents -maxdepth 2 | sort`
Expected: repo-managed AI config paths are present and no extra state files are included

- [ ] **Step 6: Commit**

```bash
git add .codex .claude .agents
git commit -m "feat: add managed AI CLI config skeleton"
```

### Task 2: Document global vs project-local ownership

**Files:**
- Modify: `docs/superpowers/specs/2026-04-12-ai-cli-dotfiles-design.md`
- Create: `docs/ai-cli-dotfiles.md`

- [ ] **Step 1: Draft short operational doc**

Create `docs/ai-cli-dotfiles.md` covering:

- what belongs in global dotfiles
- what belongs in each project repo
- which state files must never be committed
- the `AGENTS.md` + `CLAUDE.md` sharing pattern

- [ ] **Step 2: Cross-check with spec**

Read the spec and ensure the short doc matches:

Run: `sed -n '1,260p' docs/superpowers/specs/2026-04-12-ai-cli-dotfiles-design.md`
Expected: no contradictions with the operational doc

- [ ] **Step 3: Commit**

```bash
git add docs/ai-cli-dotfiles.md docs/superpowers/specs/2026-04-12-ai-cli-dotfiles-design.md
git commit -m "docs: add AI CLI dotfiles operating guide"
```

## Chunk 2: Installer refactor

### Task 3: Add explicit nested-link support to installer

**Files:**
- Modify: `install.sh`

- [ ] **Step 1: Write the failing verification scenario**

Define the expected mappings inside the plan before coding:

```text
.codex/config.toml      -> ~/.codex/config.toml
.codex/AGENTS.md       -> ~/.codex/AGENTS.md
.claude/settings.json  -> ~/.claude/settings.json
.claude/CLAUDE.md      -> ~/.claude/CLAUDE.md
.agents/skills         -> ~/.agents/skills
```

Expected failure in current code: `install.sh` only processes `.config/*` plus fixed home dotfiles.

- [ ] **Step 2: Refactor installer around generic link helpers**

Update `install.sh` so it can:

- ensure parent directories exist
- link an arbitrary source path to an arbitrary target path
- preserve the current backup behavior
- keep existing `.config/*` and home-dotfile flows intact

Suggested shape:

```bash
ensure_parent_dir() { ... }
link_path() { ... }
install_explicit_links() { ... }
install_config_tree() { ... }
install_home_dotfiles() { ... }
```

- [ ] **Step 3: Add explicit AI config mappings**

Add an explicit list for:

```text
.codex/config.toml
.codex/AGENTS.md
.codex/hooks.json
.codex/hooks
.claude/settings.json
.claude/CLAUDE.md
.claude/skills
.agents/skills
```

Only include entries that exist in the repo at runtime.

- [ ] **Step 4: Run installer dry verification**

Run: `./install.sh`
Expected: existing managed paths say linked or already linked, and AI config targets are linked without replacing whole `~/.codex` or `~/.claude`

- [ ] **Step 5: Inspect installed links**

Run:

```bash
ls -ld ~/.codex ~/.claude ~/.agents
ls -l ~/.codex ~/.claude ~/.agents
```

Expected: managed files resolve into this repo, unmanaged sibling files remain normal local files

- [ ] **Step 6: Commit**

```bash
git add install.sh
git commit -m "feat: install managed AI CLI config files"
```

## Chunk 3: Guardrails

### Task 4: Protect the repo from accidental state commits

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Add AI CLI state ignore rules**

Add rules for stateful files and directories that should never be tracked if copied into the repo by mistake, including:

```gitignore
.claude.json
.codex/auth.json
.codex/history.jsonl
.codex/session_index.jsonl
.codex/sessions/
.codex/log/
.codex/sqlite/
.codex/*.sqlite
.codex/*.sqlite-shm
.codex/*.sqlite-wal
.claude/history.jsonl
.claude/projects/
.claude/todos/
.claude/debug/
.claude/shell-snapshots/
```

Adjust patterns so curated managed files under `.codex/` and `.claude/` remain trackable.

- [ ] **Step 2: Verify ignore behavior**

Run: `git status --short --ignored`
Expected: managed files show as trackable, state paths show as ignored

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: ignore AI CLI state files"
```

## Chunk 4: Final verification

### Task 5: Verify the curated config contents

**Files:**
- Test: `.codex/config.toml`
- Test: `.claude/settings.json`
- Test: `.codex/AGENTS.md`
- Test: `.claude/CLAUDE.md`

- [ ] **Step 1: Verify Codex config content**

Run: `sed -n '1,160p' .codex/config.toml`
Expected: only curated portable settings; no project trust entries

- [ ] **Step 2: Verify Claude settings content**

Run: `sed -n '1,160p' .claude/settings.json`
Expected: only intentional global settings

- [ ] **Step 3: Verify docs**

Run:

```bash
sed -n '1,220p' docs/ai-cli-dotfiles.md
sed -n '1,220p' docs/superpowers/specs/2026-04-12-ai-cli-dotfiles-design.md
```

Expected: docs and spec agree on scope and ownership

- [ ] **Step 4: Verify install result one more time**

Run:

```bash
./install.sh
git status --short
```

Expected: installer is idempotent; only intended repo changes remain

- [ ] **Step 5: Commit**

```bash
git add .codex .claude .agents .gitignore docs install.sh
git commit -m "feat: manage Codex and Claude Code global config in dotfiles"
```

