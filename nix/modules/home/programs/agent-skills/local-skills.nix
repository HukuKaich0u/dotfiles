{
  config,
  lib,
  ...
}: let
  dotfilesDir = "${config.home.homeDirectory}/Documents/repos/personal/dotfiles";
  repoSkillsDir = ../../../../../.agents/skills;
  repoSkillsOutOfStoreDir = "${dotfilesDir}/.agents/skills";
  externalSkillNames = [
    "superpowers"
  ];
  localSkillNames =
    builtins.filter
    (name:
      let
        entryType = builtins.getAttr name (builtins.readDir repoSkillsDir);
      in
        entryType == "directory" && !(builtins.elem name externalSkillNames))
    (builtins.attrNames (builtins.readDir repoSkillsDir));
  localSkillFiles = builtins.listToAttrs (map (name: {
      name = ".agents/skills/${name}";
      value.source = config.lib.file.mkOutOfStoreSymlink "${repoSkillsOutOfStoreDir}/${name}";
    })
    localSkillNames);
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
