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
        model = "gpt-5.4"
        approval_policy = "on-request"
        model_reasoning_effort = "medium"
        web_search = "live"
        personality = "pragmatic"

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
