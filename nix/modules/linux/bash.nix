{
  config,
  lib,
  ...
}: {
  programs.bash = {
    enable = true;
    # Ubuntu / Debian の /bin/bash を login shell に使う。
    package = null;
    enableCompletion = true;
    historyFile = "${config.home.homeDirectory}/.local/state/bash/history";
    historySize = 10000;
    historyFileSize = 10000;
    historyControl = ["ignoreboth"];
    shellOptions = ["histappend" "checkwinsize" "cmdhist" "extglob" "globstar"];
    # SSH の非 login 対話 shell からも Nix の package と session 変数を使う。
    bashrcExtra = ''
      if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
      . "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"
    '';
    initExtra = lib.mkOrder 1000 ''
      # 各 prompt で追記してから他の session の履歴を取り込む。
      # Starship が直前の command の終了コードを読めるよう、最後に保存する。
      __dotfiles_history_sync() {
        local last_status=$?
        history -a || :
        history -n || :
        return "$last_status"
      }
      PROMPT_COMMAND="__dotfiles_history_sync''${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

      source ${config.xdg.configFile."bash/integrations.bash".source}
      set -o emacs
      bind '"\e\C-m": "\C-v\C-j"'

      if [ -f "$HOME/.config/bash/local.bash" ]; then
        . "$HOME/.config/bash/local.bash"
      fi
    '';
  };
}
