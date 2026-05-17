{
  config,
  ...
}: let
  codexDotfilesDir = "${config.home.homeDirectory}/Documents/repos/personal/dotfiles/.codex";
in {
  home.file = {
    ".codex/config.toml".text = ''
      [tui.keymap.global]
      open_external_editor = []
    '';
    ".codex/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/AGENTS.md";
  };
}
