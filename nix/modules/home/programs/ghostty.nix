{
  lib,
  pkgs,
  ...
}: let
  ghosttyConfig = ../assets/ghostty/config.ghostty;
in {
  # Ghostty on macOS reads from Application Support; keep XDG for Linux.
  home.file = lib.mkIf pkgs.stdenv.isDarwin {
    "Library/Application Support/com.mitchellh.ghostty/config".source = ghosttyConfig;
  };

  xdg.configFile = lib.mkIf (!pkgs.stdenv.isDarwin) {
    "ghostty/config.ghostty".source = ghosttyConfig;
  };
}
