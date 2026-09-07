{
  config,
  pkgs,
  ...
}: let
  linuxZshEnv = ../../../zsh/.zshenv;
  linuxZshProfile = ../../../zsh/.zprofile;
  linuxZshRc = pkgs.replaceVars ../../../zsh/.zshrc {
    zshAutosuggestions = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";
    zshSyntaxHighlighting = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
    zshIntegrations = config.xdg.configFile."zsh/integrations.zsh".source;
  };
in {
  home.packages = with pkgs; [
    nix-zsh-completions
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];

  home.file.".zshenv".source = linuxZshEnv;
  home.file.".zprofile".source = linuxZshProfile;
  home.file.".zshrc".source = linuxZshRc;
}
