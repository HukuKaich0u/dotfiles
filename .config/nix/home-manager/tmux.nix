{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    sensibleOnTop = false;
    plugins = with pkgs.tmuxPlugins; [
      catppuccin
      {
        plugin = tmux-sessionx;
        extraConfig = ''
          set-option -g @sessionx-bind 'o'
          set-option -g @sessionx-filter-current 'false'
          set-option -g @sessionx-preview-enabled 'true'
          set-option -g @sessionx-window-height '72%'
          set-option -g @sessionx-window-width '60%'
          set-option -g @sessionx-preview-location 'down'
          set-option -g @sessionx-preview-ratio '70%'
          set-option -g @sessionx-layout 'reverse'
          set-option -g @sessionx-prompt ' '
          set-option -g @sessionx-pointer '▌ '

          # fzf 0.53+ では builtin tmux popup を使える
          set-option -g @sessionx-fzf-builtin-tmux 'on'
        '';
      }
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
}
