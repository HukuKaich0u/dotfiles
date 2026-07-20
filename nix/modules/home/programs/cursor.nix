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
  extensionsList = ../assets/cursor/extensions.txt;
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
    "${cursorUserDir}/tasks.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${cursorAssets}/tasks.json";
      force = true;
    };
  };

  # extensions.txt にある拡張のうち未インストールのものだけ入れる (一方向 sync)。
  # リストに無い拡張は消さない。バージョンは Cursor の自動更新に任せる。
  # リスト更新: cursor --list-extensions | sort > nix/modules/home/assets/cursor/extensions.txt
  home.activation.installCursorExtensions = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      cursor_bin="$(command -v cursor || true)"
      if [ -z "$cursor_bin" ] && [ -x /usr/local/bin/cursor ]; then
        cursor_bin=/usr/local/bin/cursor
      fi
      if [ -n "$cursor_bin" ]; then
        installed="$(mktemp)"
        "$cursor_bin" --list-extensions 2>/dev/null > "$installed" || true
        while IFS= read -r ext; do
          case "$ext" in ""|\#*) continue ;; esac
          if ! grep -Fqix -- "$ext" "$installed"; then
            run "$cursor_bin" --install-extension "$ext" < /dev/null || \
              printf 'warning: failed to install cursor extension %s\n' "$ext" >&2
          fi
        done < ${extensionsList}
        rm -f "$installed"
      else
        printf 'warning: cursor CLI not found; skipping extension install\n' >&2
      fi
    ''
  );
}
