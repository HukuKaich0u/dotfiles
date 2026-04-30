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
        contents = {
          user = {
            name = "s1f102402697";
            email = "s1f102402697@iniad.org";
          };
        };
      }
    ];
  };
}
