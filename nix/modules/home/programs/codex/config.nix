{
  lib,
  pkgs,
  ...
}: let
  tomlFormat = pkgs.formats.toml {};
  settings = {
    model = "gpt-6.1-sol";
    approval_policy = "on-request";
    model_reasoning_effort = "high";
    web_search = "live";
    features.multi_agent = true;

    tui.keymap.global.open_external_editor = [];
  };
in {
  home.activation.writeCodexConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.codex" "$HOME/.codex-work"
    cp --no-preserve=mode,ownership ${tomlFormat.generate "codex-config" settings} "$HOME/.codex/config.toml"
    chmod 644 "$HOME/.codex/config.toml"
  '';

  # 共有 instructions の配布は ../agent-instructions.nix が担当する。
}
