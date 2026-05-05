{
  description = "Home Manager configuration of KokiAoyagi";

  inputs = {
    # This flake is only the entry-point map. Actual user config lives under
    # ./home-manager, and darwin-side config lives under ./nix-darwin.
    #
    # Inputs declare which upstream projects provide those building blocks.
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    ...
  }: {
    # Standalone Home Manager entry kept as a fallback / comparison path while
    # migrating toward darwin-driven management.
    homeConfigurations."KokiAoyagi" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
        overlays = [
          (import ./common/direnv-no-zsh-check-overlay.nix)
        ];
      };
      extraSpecialArgs = {inherit self;};
      modules = [
        ./home-manager/home.nix
      ];
    };

    # Main nix-darwin entry point. This is where macOS-wide settings such as
    # homebrew, system.defaults, security, and users will eventually live.
    darwinConfigurations."KokiAoyagi" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./nix-darwin/configuration.nix
        # Without this bridge module, nix-darwin cannot understand the
        # home-manager.* options declared under ./nix-darwin/home_manager.nix.
        home-manager.darwinModules.home-manager
      ];
    };
  };
}
