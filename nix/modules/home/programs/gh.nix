{
  config,
  pkgs,
  ...
}:

let
  gh = pkgs.gh;
  # git config の gh.user が指すアカウントのトークンを渡して gh を起動する。
  # git の HTTPS 認証も gh auth git-credential を通るので、push / pull も同じアカウントになる。
  # 環境変数ではなく git config で決めるため、direnv の hook が動かない agent の shell でも効く。
  ghWrapper = pkgs.writeShellScript "gh" ''
    # login / switch などは GH_TOKEN があると動かないので、git-credential 以外の auth は素通しする。
    if [ "''${1:-}" = auth ] && [ "''${2:-}" != git-credential ]; then
      exec ${gh}/bin/gh "$@"
    fi
    if [ -z "''${GH_TOKEN:-}" ] && user=$(${config.programs.git.package}/bin/git config --get gh.user 2>/dev/null); then
      GH_TOKEN=$(${gh}/bin/gh auth token --user "$user") && export GH_TOKEN
    fi
    exec ${gh}/bin/gh "$@"
  '';
in
{
  xdg.configFile."gh/config.yml".force = true;

  programs.gh = {
    enable = true;
    # 補完や man はそのまま使い、bin/gh だけ wrapper に差し替える。
    package = pkgs.symlinkJoin {
      name = "gh-${gh.version}";
      paths = [gh];
      postBuild = ''
        rm "$out/bin/gh"
        ln -s ${ghWrapper} "$out/bin/gh"
      '';
      inherit (gh) meta version;
    };
    settings = {
      git_protocol = "https";
      editor = "";
      prompt = "enabled";
      prefer_editor_prompt = "disabled";
      pager = "";
      aliases.co = "pr checkout";
      http_unix_socket = "";
      browser = "";
      color_labels = "disabled";
      accessible_colors = "disabled";
      accessible_prompter = "disabled";
      spinner = "enabled";
    };
    gitCredentialHelper.enable = true;
  };
}
