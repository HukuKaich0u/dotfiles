{
  config,
  lib,
  pkgs,
  ...
}: {
  # macOS / Linux で同じ初期化コードを使う。ツールの更新時には Nix が
  # 再生成するため、起動ごとの eval・コード生成と手動キャッシュを避けられる。
  xdg.configFile."zsh/integrations.zsh".source = pkgs.runCommand "zsh-integrations.zsh" {} ''
    export XDG_CACHE_HOME="$TMPDIR/cache"
    mkdir -p "$XDG_CACHE_HOME"

    {
      ${lib.getExe config.programs.mise.package} activate zsh
      ${lib.getExe config.programs.direnv.package} hook zsh
      ${lib.getExe config.programs.zoxide.package} init zsh ${lib.escapeShellArgs config.programs.zoxide.options}
      echo 'if [[ $TERM != "dumb" ]]; then'
      ${lib.getExe config.programs.starship.package} init zsh --print-full-init
      echo 'fi'
    } > "$out"

    ${lib.getExe pkgs.zsh} -n "$out"
  '';
}
