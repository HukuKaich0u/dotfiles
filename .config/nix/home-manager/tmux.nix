{ pkgs, ... }:

{
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
}
