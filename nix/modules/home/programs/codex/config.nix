{
  lib,
  pkgs,
  ...
}: let
  tomlFormat = pkgs.formats.toml {};
  settings = {
    model = "gpt-6-astra";
    approval_policy = "on-request";
    model_reasoning_effort = "high";
    model_verbosity = "medium";
    web_search = "live";
    personality = "pragmatic";
    features.terminal_resize_reflow = true;

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
