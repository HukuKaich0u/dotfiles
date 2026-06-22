{
  config,
  lib,
  ...
}: let
  dotfilesDir = "${config.home.homeDirectory}/Documents/repos/personal/dotfiles";
  repoSkillsDir = ../../../../../.agents/skills;
  repoSkillsOutOfStoreDir = "${dotfilesDir}/.agents/skills";

  skillsLib = import ./lib.nix {inherit lib;};
  # All leaf skills under the repo, with their path relative to .agents/skills.
  allLeaves = skillsLib.leaves repoSkillsDir;
  # superpowers is an external collection linked by external/superpowers.nix;
  # exclude its leaves here so we don't double-manage them.
  localLeaves =
    builtins.filter
    (l: !(lib.hasPrefix "superpowers/" l.relPath) && l.relPath != "superpowers")
    allLeaves;

  # Codex discovers skills recursively, so keep the category structure:
  #   .agents/skills/lang/rust -> ~/.agents/skills/lang/rust
  localSkillFiles = builtins.listToAttrs (map (l: {
      name = ".agents/skills/${l.relPath}";
      value.source = config.lib.file.mkOutOfStoreSymlink "${repoSkillsOutOfStoreDir}/${l.relPath}";
    })
    localLeaves);
in {
  home.activation.migrateAgentsSkillsDir = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    mkdir -p "$HOME/.agents"
    if [ -L "$HOME/.agents/skills" ]; then
      rm "$HOME/.agents/skills"
    fi
    mkdir -p "$HOME/.agents/skills"
  '';

  home.file =
    {
      ".agents/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.agents/AGENTS.md";
    }
    // localSkillFiles;
}
