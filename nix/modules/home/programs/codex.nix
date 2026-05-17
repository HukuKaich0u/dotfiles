{
  config,
  ...
}: let
  codexDotfilesDir = "${config.home.homeDirectory}/Documents/repos/personal/dotfiles/codex";
in {
  home.file = {
    ".codex/config.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/config.toml";
    ".codex/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/AGENTS.md";
  };
}
