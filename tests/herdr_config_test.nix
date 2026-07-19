let
  configPath = ../nix/modules/home/assets/herdr/config.toml;
  homeModulePath = ../nix/modules/home/default.nix;
  modulePath = ../nix/modules/home/programs/herdr.nix;

  sharedHomeModule = import homeModulePath {
    hunk.homeManagerModules.default = {};
  };
  sharedHomeModuleHasImports =
    sharedHomeModule ? imports && builtins.isList sharedHomeModule.imports;
  herdrImportCount = builtins.length (
    builtins.filter (homeImport: homeImport == modulePath) sharedHomeModule.imports
  );

  actualModule = import modulePath;
  expectedModule = {
    xdg.configFile."herdr/config.toml" = {
      source = configPath;
      force = true;
    };
  };

  actualConfig = builtins.fromTOML (builtins.readFile configPath);
  expectedConfig = {
    onboarding = false;

    theme.name = "terminal";
    terminal.new_cwd = "follow";

    keys = {
      prefix = "ctrl+g";
      help = "prefix+?";
      settings = "prefix+shift+s";
      detach = "prefix+d";
      reload_config = "prefix+r";
      open_notification_target = "prefix+shift+o";
      workspace_picker = "prefix+o";
      goto = "prefix+g";
      new_workspace = "prefix+shift+w";
      new_worktree = "prefix+shift+g";
      rename_workspace = "prefix+shift+r";
      close_workspace = "prefix+shift+d";
      previous_workspace = "prefix+p";
      next_workspace = "prefix+n";
      new_tab = "prefix+c";
      rename_tab = "prefix+comma";
      previous_tab = "prefix+shift+p";
      next_tab = "prefix+shift+n";
      switch_tab = "prefix+1..9";
      close_tab = "prefix+ampersand";
      copy_mode = "prefix+[";
      focus_pane_left = "prefix+h";
      focus_pane_down = "prefix+j";
      focus_pane_up = "prefix+k";
      focus_pane_right = "prefix+l";
      swap_pane_left = "";
      swap_pane_down = "";
      swap_pane_up = "";
      swap_pane_right = "";
      last_pane = "prefix+;";
      split_vertical = "prefix+shift+l";
      split_horizontal = "prefix+shift+j";
      close_pane = "prefix+x";
      zoom = "prefix+z";
      resize_mode = "prefix+s";
      toggle_sidebar = "prefix+b";
      command = [
        {
          key = "prefix+shift+h";
          type = "pane";
          command = "hunk diff --watch";
          description = "review changes with Hunk";
        }
        {
          key = "prefix+shift+k";
          type = "popup";
          command = "lazygit";
          description = "open lazygit in a popup";
          width = "80%";
          height = "80%";
        }
      ];
    };

    ui = {
      sidebar_width = 30;
      sidebar_min_width = 18;
      sidebar_max_width = 36;
      sidebar_collapsed_mode = "compact";
      mouse_capture = true;
      confirm_close = true;
      prompt_new_tab_name = true;
      pane_borders = true;
      pane_gaps = true;
      show_agent_labels_on_pane_borders = true;
      hide_tab_bar_when_single_tab = true;
      agent_panel_sort = "priority";
      toast = {
        delivery = "herdr";
        delay_seconds = 1;
      };
      sound.enabled = true;
    };

    experimental.pane_history = false;
  };
in
  if actualModule != expectedModule
  then throw "Herdr module must contain only the herdr/config.toml XDG entry with the approved source and force = true"
  else if actualConfig != expectedConfig
  then throw "Herdr config must exactly match the approved parsed TOML structure and values"
  else if !sharedHomeModuleHasImports
  then throw "Shared Home Manager module must expose an imports list"
  else if herdrImportCount != 1
  then throw "Shared Home Manager module must import programs/herdr.nix exactly once; found ${toString herdrImportCount} imports"
  else true
