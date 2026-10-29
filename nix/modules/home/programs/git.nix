{
  ...
}:

{
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user.name = "HukuKaich0u";
      user.email = "170926658+HukuKaich0u@users.noreply.github.com";
      # gh と git の HTTPS 認証に使うアカウント。gh.nix の wrapper が読む。
      gh.user = "HukuKaich0u";
      core.editor = "nvim";
      pull.rebase = false;
    };
    includes = [
      {
        condition = "gitdir:~/Documents/repos/university/";
        contents = {
          user = {
            name = "s1f102402697";
            email = "s1f102402697@iniad.org";
          };
        };
      }
      # 大学アカウントの判定は置き場所ではなく remote の URL で行う。
      # university/ の下にも個人アカウントの repo があるため。
      {
        condition = "hasconfig:remote.*.url:git@github-university:*/**";
        contents.gh.user = "s1f102402697";
      }
      {
        condition = "hasconfig:remote.*.url:https://github.com/s1f102402697/**";
        contents.gh.user = "s1f102402697";
      }
      # 公開 repo に置けない端末ごとの設定。ファイルが無ければ Git は無視する。
      {path = "~/.config/git/local";}
    ];
  };
}
