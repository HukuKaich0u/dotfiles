{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    git
    ripgrep
    fd
    gnumake
    tmux
    # Added during the Neovim migration, but installed as shared CLI tools.
    lazygit
    imagemagick
  ];
}
