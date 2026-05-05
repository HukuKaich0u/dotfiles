{
  pkgs,
  ...
}:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = true;
    withRuby = true;
  };

  home.packages = with pkgs; [
    git
    ripgrep
    fd
    gnumake
    tmux
    lazygit
    imagemagick
    pngpaste
    pkgs."ascii-image-converter"
  ];

  xdg.configFile."nvim".source = ./nvim;
}
