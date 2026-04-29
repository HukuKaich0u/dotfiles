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
      core.editor = "nvim";
      pull.rebase = false;
    };
    includes = [
      {
        condition = "gitdir:~/Documents/repos/university/";
        path = "~/.config/git/config-university";
      }
    ];
  };

  xdg.configFile."git/config-university".source = ./git/config-university;
}
