{...}: {
  programs.starship = {
    enable = true;
    # 初期化コードは zsh-integrations.nix でビルド時に生成する。
    enableZshIntegration = false;
    settings = {
      add_newline = false;
      # 全幅の fill と複数行を避け、リサイズ時の折り返し・再描画を安定させる。
      format = "$hostname$directory$git_branch$git_status$git_state$cmd_duration$jobs$character";
      right_format = "";

      hostname = {
        ssh_only = true;
        format = "[$hostname]($style) ";
        style = "bold #bb9af7";
      };

      directory = {
        truncation_length = 2;
        truncate_to_repo = true;
        truncation_symbol = "…/";
        read_only = " ro";
        format = "[$path]($style)[$read_only]($read_only_style) ";
        style = "bold #7aa2f7";
        read_only_style = "#e0af68";
      };

      git_branch = {
        truncation_length = 20;
        truncation_symbol = "…";
        format = "[$branch]($style) ";
        style = "#9aa5ce";
      };

      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
        style = "#e0af68";
        conflicted = "=";
        ahead = "↑";
        behind = "↓";
        diverged = "↕";
        untracked = "?";
        stashed = "\\$";
        modified = "!";
        staged = "+";
        renamed = "»";
        deleted = "×";
      };

      git_state = {
        format = "[$state( $progress_current/$progress_total)]($style) ";
        style = "bold #f7768e";
      };

      cmd_duration = {
        min_time = 2000;
        format = "[$duration]($style) ";
        style = "#737aa2";
      };

      jobs = {
        format = "[$symbol$number]($style) ";
        symbol = "&";
        style = "#737aa2";
      };

      character = {
        success_symbol = "[❯](bold #9ece6a)";
        error_symbol = "[❯](bold #f7768e)";
        vimcmd_symbol = "[❮](bold #bb9af7)";
      };
    };
  };
}
