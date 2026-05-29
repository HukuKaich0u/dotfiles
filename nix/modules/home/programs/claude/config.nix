{
  config,
  ...
}: let
  claudeDotfilesDir = "${config.home.homeDirectory}/Documents/repos/personal/dotfiles/.claude";
in {
  home.file = {
    ".claude/CLAUDE.md" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/CLAUDE.md";
    };
  };
}
