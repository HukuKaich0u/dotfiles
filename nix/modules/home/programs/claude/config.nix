{
  config,
  ...
}: let
  claudeDotfilesDir = "${config.home.homeDirectory}/Documents/repos/personal/dotfiles/.claude";
in {
  # Claude Code 本体は公式 native インストーラ管理 (~/.local/bin/claude, 自己アップデート)
  # のため package = null とし、settings.json のみ宣言的に生成する。
  programs.claude-code = {
    enable = true;
    package = null;
    settings = {
      model = "opus[1m]";
      alwaysThinkingEnabled = false;
      autoUpdatesChannel = "latest";
      theme = "dark-daltonized";
      editorMode = "vim";
      language = "japanese";
      # 毎回の承認を省くため全ツールを無確認で実行する。
      permissions.defaultMode = "bypassPermissions";
    };
  };

  # CLAUDE.md はリポジトリ編集を即反映させるため out-of-store symlink を維持する
  # (モジュールの context は store コピーになるので使わない)。
  home.file = {
    "CLAUDE.md" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/CLAUDE.md";
    };
    ".claude/CLAUDE.md" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/CLAUDE.md";
    };
  };
}
