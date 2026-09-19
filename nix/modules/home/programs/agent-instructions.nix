{...}: let
  source = ../../../../agents/AGENTS.md;
in {
  home.file = {
    ".claude/AGENTS.md" = {inherit source;};
    ".codex/AGENTS.md" = {inherit source;};
  };
}
