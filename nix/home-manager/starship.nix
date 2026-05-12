{
  ...
}: {
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;

      format = builtins.concatStringsSep "" [
        "$hostname"
        "$directory  "
        "$git_branch"
        "$git_status"
        # "\${custom.docker_context}"
        "$kubernetes"
        "$terraform"
        "$direnv"
        "$fill"
        "$cmd_duration"
        "$time"
        "\n$character"
      ];

      python = {
        format = "[](fg:#f2f7ff)[ $virtualenv ]($style)[](fg:#f2f7ff)";
        style = "bold fg:#1a1b26 bg:#f2f7ff";
      };

      fill.symbol = "─";

      hostname = {
        ssh_only = true;
        format = "[](fg:#d7e6ff)[ $hostname ]($style)[](fg:#d7e6ff)";
        style = "bold fg:#1a1b26 bg:#d7e6ff";
      };

      directory = {
        truncation_length = 6;
        truncation_symbol = " ";
        truncate_to_repo = false;
        home_symbol = "~";
        read_only = " 󰌾 ";
        format = "[](fg:#9fc5ff)[ $path ]($style)[$read_only]($read_only_style)[](fg:#9fc5ff)";
        style = "bold fg:#1a1b26 bg:#9fc5ff";
        read_only_style = "bold fg:#1a1b26 bg:#9fc5ff";
      };

      direnv = {
        disabled = false;
        format = "[](fg:#d2ddff)[ $symbol$allowed ]($style)[](fg:#d2ddff)";
        style = "bold fg:#1a1b26 bg:#d2ddff";
      };

      git_branch = {
        symbol = "";
        style = "bold fg:#eef4ff bg:#4f7ae8";
        format = "[](fg:#4f7ae8)[ $symbol $branch ]($style)[](fg:#4f7ae8)";
      };

      # custom.docker_context = {
      #   shell = [ "sh" ];
      #   when = ''
      #     command -v docker >/dev/null 2>&1 || exit 1
      #
      #     if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
      #       exit 0
      #     fi
      #
      #     repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 1
      #
      #     find "$repo_root" \
      #       \( -name .git -o -name node_modules -o -name .direnv -o -name .devenv \) -prune -o \
      #       \( -type f \( -name Dockerfile -o -name Containerfile -o -name docker-compose.yml -o -name docker-compose.yaml -o -name compose.yml -o -name compose.yaml -o -name devcontainer.json \) -o -type d \( -name .devcontainer -o -name docker \) \) \
      #       -print -quit | grep -q .
      #   '';
      #   command = ''
      #     if [ -n "$DOCKER_CONTEXT" ]; then
      #       printf '%s' "$DOCKER_CONTEXT"
      #       exit 0
      #     fi
      #
      #     ctx="$(awk -F'"' '/currentContext/ {print $4; exit}' "$HOME/.docker/config.json" 2>/dev/null)"
      #     [ -n "$ctx" ] || ctx=default
      #     printf '%s' "$ctx"
      #   '';
      #   style = "bold fg:#f5f6ff bg:#1f52e4";
      #   format = "[](fg:#1f52e4)[  $output ]($style)[](fg:#1f52e4)";
      # };

      kubernetes = {
        disabled = false;
        symbol = "☸";
        detect_files = [
          "k8s.yaml"
          "k8s.yml"
          "kustomization.yaml"
          "kustomization.yml"
          "Chart.yaml"
          "helmfile.yaml"
          "helmfile.yml"
        ];
        detect_folders = [
          "k8s"
          "kubernetes"
          "helm"
          "charts"
        ];
        style = "bold fg:#f8f1ff bg:#3029dc";
        format = "[](fg:#3029dc)[ $symbol $context( \\($namespace\\)) ]($style)[](fg:#3029dc)";
      };

      terraform = {
        symbol = "󱁢";
        detect_extensions = [ "tf" "tfplan" "tfstate" ];
        detect_files = [ ".terraform.lock.hcl" ];
        detect_folders = [ ".terraform" ];
        style = "bold fg:#fdeeff bg:#4f18d8";
        format = "[](fg:#4f18d8)[ $symbol $workspace ]($style)[](fg:#4f18d8)";
      };

      git_status = {
        conflicted = "=";
        ahead = "⇡";
        behind = "⇣";
        diverged = "⇕";
        up_to_date = "";
        untracked = "?";
        stashed = "\\$";
        modified = "!";
        staged = "+";
        renamed = "»";
        deleted = "✘";
        typechanged = "";
        style = "bold fg:#eef4ff bg:#3b63d1";
        format = "[](fg:#3b63d1)[ $all_status$ahead_behind ]($style)[](fg:#3b63d1)";
      };

      cmd_duration = {
        min_time = 1;
        style = "bold fg:#fdefff bg:#43178f";
        format = "[](fg:#43178f)[ $duration ]($style)[](fg:#43178f)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bold fg:#edf4ff bg:#2a4177";
        format = "[](fg:#2a4177)[  $time ]($style)[](fg:#2a4177)";
      };

      character.vimcmd_symbol = "[V](bold green) ";
    };
  };
}
