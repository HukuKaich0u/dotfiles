{ pkgs, ... }:

let
  battery_script="${pkgs.tmuxPlugins.battery}/share/tmux-plugins/battery/scripts";
  wifi_status_script=pkgs.writeShellScript "tmux-wifi-status" ''
    print_online() {
      printf '󰖩 on'
    }

    print_offline() {
      printf '󰖪 off'
    }

    if [ "$(uname)" = "Darwin" ]; then
      dev="$(networksetup -listallhardwareports 2>/dev/null | awk '/Hardware Port: (Wi-Fi|AirPort)/ { getline; print $2; exit }')"
      summary="$(ipconfig getsummary "$dev" 2>/dev/null)"

      if [ -n "$dev" ] &&
        printf '%s\n' "$summary" | grep -q 'InterfaceType : WiFi' &&
        printf '%s\n' "$summary" | grep -q ' SSID : '; then
        print_online
      else
        print_offline
      fi
    else
      if command -v nmcli >/dev/null 2>&1; then
        if nmcli -t -f TYPE,STATE device 2>/dev/null | grep -q '^wifi:connected$'; then
          print_online
          exit 0
        fi
      fi

      if command -v iwgetid >/dev/null 2>&1; then
        if iwgetid --raw >/dev/null 2>&1 && [ -n "$(iwgetid --raw 2>/dev/null)" ]; then
          print_online
          exit 0
        fi
      fi

      for wireless_dir in /sys/class/net/*/wireless; do
        if [ -d "$wireless_dir" ]; then
          operstate_file="$(dirname "$wireless_dir")/operstate"
          if [ -r "$operstate_file" ] && [ "$(cat "$operstate_file")" = "up" ]; then
            print_online
            exit 0
          fi
        fi
      done

      if ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
        print_online
      else
        print_offline
      fi
    fi
  '';
in

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
    ];
    extraConfig = ''
      ${builtins.readFile ../assets/tmux/tmux.conf}

      # Home Manager loads plugins before extraConfig, so status placeholders
      # from tmux-battery/online-status do not get a second interpolation pass.
      set-option -g status-right ""
      set-option -ga status-right "#[bg=default,fg=#{@thm_blue}] #(${battery_script}/battery_icon.sh) #(${battery_script}/battery_percentage.sh) "
      set-option -ga status-right "#[bg=default,fg=#{@thm_blue}] #(${wifi_status_script}) "
      set-option -ga status-right "#[bg=default,fg=#{@thm_blue}] 󰭦 %Y-%m-%d 󰅐 %H:%M "
    '';
  };
}
