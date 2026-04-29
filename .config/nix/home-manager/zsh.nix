{
  config,
  lib,
  ...
}: let
  zshDotDir = "${config.home.homeDirectory}/.config/zsh";
in {
  home.file.".config/zsh/env.zsh".source = ./zsh/env.zsh;
  home.file.".config/zsh/homebrew.zsh".source = ./zsh/homebrew.zsh;

  programs.starship.enable = true;

  programs.zsh = {
    enable = true;
    dotDir = zshDotDir;
    enableCompletion = true;
    completionInit = ''
      autoload -Uz compinit

      export ZSH_CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
      mkdir -p "$ZSH_CACHE_DIR"

      compinit -d "$ZSH_CACHE_DIR/.zcompdump"
    '';
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history.path = "${config.home.homeDirectory}/.local/state/zsh/.zsh_history";
    shellAliases = {
      gotest = ''oj t -c "go run main.go" -d tests'';
      gobuild = "go build -o main.out main.go";
      gobintest = ''ojt -c "main/a.out"'';
      pytest = ''oj t -c "python3 main.py" -d tests'';
      rstest = ''oj t -c "rustc main.rs && ./main" -d tests'';
      rsbuild = "rustc main.rs";
      rsbintest = ''oj t -c "./main" -d tests'';
      nv = "nvim";
      tm = "tmux";
      codex = "codex --no-alt-screen";
      codex-alt = "command codex";
      tmls = "tmux list-sessions";
      tma = "tmux a -t";
      tmnew = "tmux new -s";
    };
    envExtra = ''
      if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
      fi
    '';
    profileExtra = ''
      source "$ZDOTDIR/homebrew.zsh"
    '';
    initContent = lib.mkMerge [
      (lib.mkOrder 550 ''
        source "$ZDOTDIR/env.zsh"
      '')
      (lib.mkOrder 1000 ''
        # Shift+Enter が Esc+Enter として届く端末でも、複数行入力の改行として扱いやすくする。
        bindkey '^[^M' self-insert-unmeta
      '')
    ];
  };
}
