{ pkgs, ... }:

{
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

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = [
      {
        user.name = "HukuKaich0u";
        user.email = "170926658+HukuKaich0u@users.noreply.github.com";
        core.editor = "nvim";
        pull.rebase = false;

        credential."https://github.com".helper = "";
        credential."https://gist.github.com".helper = "";
      }
      {
        credential."https://github.com".helper = "!/opt/homebrew/bin/gh auth git-credential";
        credential."https://gist.github.com".helper = "!/opt/homebrew/bin/gh auth git-credential";
      }
    ];
    includes = [
      {
        condition = "gitdir:~/Documents/repos/university/";
        path = "~/.config/git/config-university";
      }
    ];
  };

  xdg.configFile."git/config-university".source = ./git/config-university;

  programs.tmux = {
    enable = true;
    sensibleOnTop = false;
    plugins = with pkgs.tmuxPlugins; [
      catppuccin
      tmux-sessionx
      {
        plugin = resurrect;
        extraConfig = ''
          # tmux 起動直後や最後の session close では、空の状態で resurrect の
          # last を上書きしないよう created/closed では即時保存しない
          set-hook -g session-renamed 'run-shell "${resurrect}/share/tmux-plugins/resurrect/scripts/save.sh quiet"'
        '';
      }
      continuum
      battery
      online-status
    ];
    extraConfig = builtins.readFile ./tmux/tmux.conf;
  };

  programs.home-manager.enable = true;
}
