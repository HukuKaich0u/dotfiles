{
  config,
  lib,
  pkgs,
  ...
}: let
  dotfilesDir = "${config.home.homeDirectory}/Documents/repos/personal/dotfiles";
  repoSkillsDir = ../../../../../.agents/skills;
  repoSkillsOutOfStoreDir = "${dotfilesDir}/.agents/skills";

  # Claude Code only scans ONE level under ~/.claude/skills/, expecting
  # ~/.claude/skills/<name>/SKILL.md. Codex discovers skills recursively under
  # ~/.agents/skills/, so a "collection" skill (a dir of sub-skills, no top-level
  # SKILL.md) works for Codex but is invisible to Claude. We bridge that here by
  # flattening collections into one symlink per leaf skill.

  isDir = path: name: (builtins.getAttr name (builtins.readDir path)) == "directory";
  hasSkillMd = path: builtins.pathExists "${path}/SKILL.md";
  subdirs = path:
    builtins.filter (name: isDir path name)
    (builtins.attrNames (builtins.readDir path));

  # Local repo skills: kept as out-of-store symlinks so edits in the repo apply
  # live, matching local-skills.nix. These are all leaf skills today.
  localSkillNames = builtins.filter (isDir repoSkillsDir) (subdirs repoSkillsDir);
  localSkillLinks = builtins.listToAttrs (map (name: {
      name = ".claude/skills/${name}";
      value.source = config.lib.file.mkOutOfStoreSymlink "${repoSkillsOutOfStoreDir}/${name}";
    })
    localSkillNames);

  # Superpowers ships as a collection: one sub-dir per leaf skill, each with its
  # own SKILL.md. Link each leaf so Claude can see them individually.
  superpowersSrc = import ./external/superpowers-src.nix {inherit pkgs;};
  superpowersSkillsDir = "${superpowersSrc}/skills";
  superpowersLeafNames =
    builtins.filter (name: hasSkillMd "${superpowersSkillsDir}/${name}")
    (subdirs superpowersSkillsDir);
  superpowersLinks = builtins.listToAttrs (map (name: {
      name = ".claude/skills/${name}";
      value.source = "${superpowersSkillsDir}/${name}";
    })
    superpowersLeafNames);
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
    for name in ${lib.escapeShellArgs (localSkillNames ++ superpowersLeafNames)}; do
      if [ -L "$HOME/.claude/skills/$name" ]; then
        rm "$HOME/.claude/skills/$name"
      fi
    done
  '';

  home.file = localSkillLinks // superpowersLinks;
}
