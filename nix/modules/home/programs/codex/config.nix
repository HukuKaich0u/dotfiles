{
  lib,
  pkgs,
  ...
}:
let
  settings = {
    model = "gpt-6.1-sol";
    approval_policy = "on-request";
    approvals_reviewer = "auto_review";
    sandbox_mode = "workspace-write";
    model_reasoning_effort = "high";
    web_search = "live";
    features.multi_agent = true;

    tui.notifications = [
      "agent-turn-complete"
      "approval-requested"
    ];
    # auto では Rex で音しか鳴らなかった。Rex は OSC 9 を受けると macOS の
    # 通知を出すので明示する。
    tui.notification_method = "osc9";
    tui.notification_condition = "always";
    tui.keymap.global.open_external_editor = [ ];

    # Codex には marketplace の自動更新が無い。配布元を宣言しておけば
    # `codex plugin marketplace upgrade` だけで全 plugin を更新できる。
    marketplaces = {
      pstack-claude = {
        source_type = "git";
        source = "https://github.com/michael-denyer/pstack-claude.git";
      };
      i-have-adhd = {
        source_type = "git";
        source = "https://github.com/ayghri/i-have-adhd.git";
      };
      drawio = {
        source_type = "git";
        source = "https://github.com/jgraph/drawio-mcp.git";
      };
    };
    plugins = {
      "pstack@pstack-claude".enabled = true;
      "i-have-adhd@i-have-adhd".enabled = true;
      "drawio@drawio".enabled = true;
    };
  };
  codexSettingsOverlay = pkgs.writeText "codex-settings-overlay.json" (builtins.toJSON settings);
  codexDrawioRules = pkgs.writeText "codex-drawio.rules" ''
    prefix_rule(
        pattern = ["/Applications/draw.io.app/Contents/MacOS/draw.io"],
        decision = "allow",
        match = [["/Applications/draw.io.app/Contents/MacOS/draw.io", "-x", "-f", "png", "-o", "a.png", "a.drawio"]],
    )
    prefix_rule(
        pattern = ["drawio"],
        decision = "allow",
        match = [["drawio", "-x", "-f", "png", "-o", "a.png", "a.drawio"]],
        not_match = [["open", "a.drawio"]],
    )
  '';
in
{
  # config.toml には Codex 自身も書き込む (信頼済みフォルダ、hook の信頼、
  # CLI で追加した marketplace)。上書きするとそれらが消えるため、
  # activation で key 単位 merge し、管理キーだけを揃える。
  home.activation.mergeCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.codex" "$HOME/.codex-work"

    codex_config="$HOME/.codex/config.toml"
    codex_base="$(mktemp)"
    codex_merged="$(mktemp)"

    if ! { [ -f "$codex_config" ] && ${pkgs.remarshal}/bin/toml2json "$codex_config" > "$codex_base" 2>/dev/null; }; then
      printf '{}\n' > "$codex_base"
    fi

    ${pkgs.jq}/bin/jq -S -s '.[0] * .[1]' "$codex_base" ${codexSettingsOverlay} \
      | ${pkgs.remarshal}/bin/json2toml > "$codex_merged"
    cp --no-preserve=mode,ownership "$codex_merged" "$codex_config"
    # Codex が書く MCP の env などを残すようになったため、本人以外は読めなくする。
    chmod 600 "$codex_config"
    rm -f "$codex_base" "$codex_merged"
  '';

  # draw.io Desktop は sandbox 内だと WindowServer に登録できず起動直後に
  # abort し、macOS のクラッシュダイアログが出る。allow は sandbox 外で実行
  # させる。Codex が承認時に書き込む default.rules とは別ファイルにする。
  # home.file の symlink だと Codex 0.166.0 は読まなかったため実ファイルで置く。
  home.activation.writeCodexDrawioRules = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.codex/rules"
    install -m 644 ${codexDrawioRules} "$HOME/.codex/rules/drawio.rules"
  '';

  # 共有 instructions の配布は ../agent-instructions.nix が担当する。
}
