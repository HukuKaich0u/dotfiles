{
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
}
