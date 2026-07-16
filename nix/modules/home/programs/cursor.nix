{
  config,
  lib,
  pkgs,
  ...
}: let
  # Cursor は settings.json / keybindings.json へ自身で書き込む (GUI 変更、
  # 拡張が書くキー) 上に JSONC のコメントを含むため、store への固定 symlink
  # や jq merge は使えない。repo 内の実ファイルへの out-of-store symlink に
  # して、GUI からの変更を git diff で拾って commit する運用にする。
  dotfilesDir = "${config.home.homeDirectory}/Documents/repos/personal/dotfiles";
  cursorAssets = "${dotfilesDir}/nix/modules/home/assets/cursor";
  cursorUserDir = "Library/Application Support/Cursor/User";
in {
  home.file = lib.mkIf pkgs.stdenv.isDarwin {
    "${cursorUserDir}/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${cursorAssets}/settings.json";
      force = true;
    };
    "${cursorUserDir}/keybindings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${cursorAssets}/keybindings.json";
      force = true;
    };
  };
}
