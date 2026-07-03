{
  lib,
  pkgs,
  ...
}: let
  claudeSettings = {
    model = "opus[1m]";
    alwaysThinkingEnabled = false;
    autoUpdatesChannel = "latest";
    theme = "dark-daltonized";
    editorMode = "vim";
    language = "japanese";
    permissions.defaultMode = "auto";
  };
  claudeSettingsOverlay = pkgs.writeText "claude-settings-overlay.json" (builtins.toJSON claudeSettings);
in {
  # Claude Code 本体は公式 native インストーラ管理 (~/.local/bin/claude, 自己アップデート)
  # のため package = null とする。settings.json は activation で key 単位 merge
  # し、Claude が書き込む動的な state はなるべく温存する。
  programs.claude-code = {
    enable = true;
    package = null;
  };

  home.activation.mergeClaudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.claude"

    settings_target="$HOME/.claude/settings.json"
    base_file="$(mktemp)"
    merged_file="$(mktemp)"
    trap 'rm -f "$base_file" "$merged_file"' EXIT

    if [ -f "$settings_target" ] && ${pkgs.jq}/bin/jq -e 'type == "object"' "$settings_target" >/dev/null 2>&1; then
      cp --no-preserve=mode,ownership "$settings_target" "$base_file"
    else
      printf '{}\n' > "$base_file"
    fi

    ${pkgs.jq}/bin/jq -S -s '.[0] * .[1]' "$base_file" ${claudeSettingsOverlay} > "$merged_file"
    cp --no-preserve=mode,ownership "$merged_file" "$settings_target"
    chmod 644 "$settings_target"
  '';

  # NOTE: CLAUDE.md / 指示ファイルは APM の instructions/core (~/.apm/apm.yml)
  # から配布する。Nix はここでは settings.json のマージだけ担当する。
}
