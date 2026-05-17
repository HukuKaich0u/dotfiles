{
  config,
  ...
}: let
  codexDotfilesDir = "${config.home.homeDirectory}/Documents/repos/personal/dotfiles/.codex";
in {
  home.file = {
    ".codex/config.toml" = {
      force = true;
      text = ''
        [tui.keymap.global]
        open_external_editor = []
      '';
    };
    ".codex/AGENTS.md" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/AGENTS.md";
    };
  };
}
