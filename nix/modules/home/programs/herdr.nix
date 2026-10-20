{
  lib,
  pkgs,
  ...
}: let
  configSource = ../assets/herdr/config.toml;
  # Reject incompatible schemas and keybinding conflicts before deployment.
  checkedConfig = pkgs.runCommand "herdr-config.toml" {} ''
    export XDG_CONFIG_HOME="$TMPDIR/config"
    export XDG_STATE_HOME="$TMPDIR/state"
    HERDR_CONFIG_PATH=${configSource} ${lib.getExe pkgs.herdr} config check
    cp ${configSource} "$out"
  '';
in {
  xdg.configFile."herdr/config.toml" = {
    source = checkedConfig;
    force = true;
  };
}
