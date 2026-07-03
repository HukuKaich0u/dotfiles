{
  lib,
  pkgs,
  ...
}: let
  skillsLib = import ../lib.nix {inherit lib;};

  superpowersSrc = import ./superpowers-src.nix {inherit pkgs;};
  superpowersSkillsDir = "${superpowersSrc}/skills";

  # Claude Code only scans ONE level under ~/.claude/skills/, expecting
  # ~/.claude/skills/<name>/SKILL.md, so each leaf skill is flattened to a
  # single symlink keyed by its own directory name (category dropped).
  # Codex discovers skills recursively, so ~/.agents/skills/superpowers keeps
  # the whole collection as one dirlink.
  superpowersLeaves = skillsLib.leaves superpowersSkillsDir;
  superpowersClaudeLinks = builtins.listToAttrs (map (l: {
      name = ".claude/skills/${l.name}";
      value.source = "${superpowersSkillsDir}/${l.relPath}";
    })
    superpowersLeaves);

  flatNames = map (l: l.name) superpowersLeaves;
in {
  # Remove any pre-existing per-skill symlinks we are about to recreate, so
  # checkLinkTargets does not abort on a manual link colliding with ours.
  home.activation.cleanSuperpowersClaudeLinks = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    for name in ${lib.escapeShellArgs flatNames}; do
      if [ -L "$HOME/.claude/skills/$name" ]; then
        rm "$HOME/.claude/skills/$name"
      fi
    done
  '';

  home.file =
    {
      ".agents/skills/superpowers".source = superpowersSkillsDir;
    }
    // superpowersClaudeLinks;
}
