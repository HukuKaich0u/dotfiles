{
  config,
  lib,
  pkgs,
  ...
}: let
  shell =
    if config.programs.bash.enable
    then "bash"
    else "zsh";
  extension =
    if shell == "zsh"
    then "zsh"
    else "bash";
  shellPackage =
    if shell == "zsh"
    then pkgs.zsh
    else pkgs.bash;
in {
  # macOS / Linux の各 shell 用に初期化する。ツールの更新時には Nix が
  # 再生成するため、起動ごとの eval・コード生成と手動キャッシュを避けられる。
  xdg.configFile."${shell}/integrations.${extension}".source = pkgs.runCommand "${shell}-integrations.${extension}" {} ''
    export XDG_CACHE_HOME="$TMPDIR/cache"
    mkdir -p "$XDG_CACHE_HOME"

    {
      ${lib.getExe config.programs.mise.package} activate ${shell}
      ${lib.getExe config.programs.direnv.package} hook ${shell}
      ${lib.getExe config.programs.zoxide.package} init ${shell} ${lib.escapeShellArgs config.programs.zoxide.options}
      echo 'if [[ $TERM != "dumb" ]]; then'
      ${lib.getExe config.programs.starship.package} init ${shell} --print-full-init
      echo 'fi'
    } > "$out"

    ${lib.getExe shellPackage} -n "$out"
  '';
}
