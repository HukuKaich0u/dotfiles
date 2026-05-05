{
  ...
}:

{
  imports = [
    ./bacon.nix
    ./git.nix
    ./gh.nix
    ./mise.nix
    ./starship.nix
    ./tmux.nix
    ./wezterm.nix
    ./yazi.nix
    ./zsh.nix
  ];

  home.username = "KokiAoyagi";
  home.homeDirectory = "/Users/KokiAoyagi";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/KokiAoyagi/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
  };

  programs.home-manager.enable = true;
}
