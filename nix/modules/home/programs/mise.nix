{
  config,
  lib,
  ...
}: let
  nodeVersion = config.programs.mise.globalConfig.tools.node;
in {
  programs.mise.enable = true;
  programs.mise.enableZshIntegration = true;
  programs.mise.globalConfig = {
    tools = {
      node = "24";
      go = "1.26";
      java = "25";
    };
    settings = {};
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.activation.enableCorepack = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.local/bin"

    if "${config.programs.mise.package}/bin/mise" where node@"${nodeVersion}" >/dev/null 2>&1; then
      "${config.programs.mise.package}/bin/mise" exec node@"${nodeVersion}" -- \
        corepack enable --install-directory "$HOME/.local/bin"
    fi
  '';
}
