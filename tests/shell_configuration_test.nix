let
  flake = builtins.getFlake ("git+file://" + toString ../. + "?dir=nix");
  pkgs = import flake.inputs.nixpkgs {
    system = builtins.currentSystem;
    config.allowUnfree = true;
    overlays = import ../nix/overlays;
  };
  # Linux の Bash module をホストの package で build し、Mac でも実行検証する。
  home = flake.inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = {inherit (flake.inputs) hunk;};
    modules = [
      ../nix/modules/linux/default.nix
      {
        home.username = pkgs.lib.mkForce "shell-test";
        home.homeDirectory = pkgs.lib.mkForce (builtins.getEnv "DOTFILES_TEST_HOME");
      }
    ];
  };
in
  pkgs.linkFarm "bash-test-fixtures" [
    {
      name = "bashrc";
      path = home.config.home.file.".bashrc".source;
    }
    {
      name = "bash";
      path = "${pkgs.bashInteractive}/bin/bash";
    }
    {
      name = "node";
      path = "${pkgs.nodejs_24}/bin/node";
    }
    {
      name = "remove-legacy-shims";
      path = pkgs.writeShellScript "remove-legacy-shims" home.config.home.activation.removeLegacyCorepackShims.data;
    }
  ]
