{pkgs, ...}: let
  linuxZshEnv = ../../../zsh/.zshenv;
  linuxZshRc = pkgs.substituteAll {
    src = ../../../zsh/.zshrc;
    zshAutosuggestions = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";
    zshSyntaxHighlighting = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
  };
in {
  home.packages = with pkgs; [
    nix-zsh-completions
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];

  home.file.".zshenv".source = linuxZshEnv;
  home.file.".zshrc".source = linuxZshRc;
}
