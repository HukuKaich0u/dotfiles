{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = true;
    withRuby = true;
  };

  xdg.configFile."nvim".source = ../assets/nvim;
}
