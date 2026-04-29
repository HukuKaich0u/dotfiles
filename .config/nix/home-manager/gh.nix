{
  ...
}:

{
  xdg.configFile."gh/config.yml".force = true;

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
      editor = "";
      prompt = "enabled";
      prefer_editor_prompt = "disabled";
      pager = "";
      aliases.co = "pr checkout";
      http_unix_socket = "";
      browser = "";
      color_labels = "disabled";
      accessible_colors = "disabled";
      accessible_prompter = "disabled";
      spinner = "enabled";
    };
    gitCredentialHelper.enable = true;
  };
}
