{
  lib,
  pkgs,
  ...
}: let
  skillsLib = import ./lib.nix {inherit lib;};

  # Claude Code only scans ONE level under ~/.claude/skills/, expecting
  # ~/.claude/skills/<name>/SKILL.md. So every leaf skill is flattened to a
  # single symlink keyed by its own directory name (category dropped).

  # NOTE: agent-kit's own skills are NOT distributed from here anymore — they are
  # managed and distributed via APM (~/.apm/apm.yml) instead, so this module only
  # ships the external superpowers collection. agent-kit remains a flake input
  # purely for instructions / CLAUDE.md (see claude/config.nix), not skills.

  # Superpowers ships as a collection of leaf skills; flatten each via the same
  # recursive helper against its store path.
  superpowersSrc = import ./external/superpowers-src.nix {inherit pkgs;};
  superpowersSkillsDir = "${superpowersSrc}/skills";
  superpowersLeaves = skillsLib.leaves superpowersSkillsDir;
  superpowersLinks = builtins.listToAttrs (map (l: {
      name = ".claude/skills/${l.name}";
      value.source = "${superpowersSkillsDir}/${l.relPath}";
    })
    superpowersLeaves);

  allFlatNames = map (l: l.name) superpowersLeaves;
in {
  home.activation.migrateClaudeSkillsDir = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    mkdir -p "$HOME/.claude"
    # Drop stale hand-made symlinks / dirlink backups so home-manager owns the dir.
    if [ -L "$HOME/.claude/skills" ]; then
      rm "$HOME/.claude/skills"
    fi
    rm -f "$HOME/.claude/skills.dirlink.backup"
    mkdir -p "$HOME/.claude/skills"
    # Remove any pre-existing per-skill symlinks we are about to recreate, so
    # checkLinkTargets does not abort on a manual link colliding with ours.
    for name in ${lib.escapeShellArgs allFlatNames}; do
      if [ -L "$HOME/.claude/skills/$name" ]; then
        rm "$HOME/.claude/skills/$name"
      fi
    done
  '';

  home.file = superpowersLinks;
}
