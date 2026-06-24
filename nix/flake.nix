{
  description = "Home Manager configuration of KokiAoyagi";

  inputs = {
    # This flake is only the entry-point map. Actual user config lives under
    # ./modules/home, and darwin-side config lives under ./modules/darwin.
    #
    # Inputs declare which upstream projects provide those building blocks.
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    agent-kit = {
      url = "github:HukuKaich0u/agent-kit";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    ...
  }: let
    agentKitSrc = inputs."agent-kit";
    sharedNixpkgs = import ./lib/nixpkgs.nix;
    mkPkgs = system: import nixpkgs {
      inherit system;
      config = sharedNixpkgs.nixpkgs.config;
      overlays = sharedNixpkgs.nixpkgs.overlays;
    };
  in {
    # Standalone Home Manager entry is now reserved for Linux while macOS
    # moves through nix-darwin below.
    homeConfigurations."kokiaoyagi" = home-manager.lib.homeManagerConfiguration {
      pkgs = mkPkgs "aarch64-linux";
      extraSpecialArgs = {
        inherit self agentKitSrc;
      };
      modules = [
        ./modules/home/default.nix
        ./modules/linux/default.nix
      ];
    };

    # Main nix-darwin entry point. This is where macOS-wide settings such as
    # homebrew, system.defaults, security, and users will eventually live.
    darwinConfigurations."KokiAoyagi" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = {
        inherit self agentKitSrc;
      };
      modules = [
        ./modules/darwin/system.nix
        # Without this bridge module, nix-darwin cannot understand the
        # home-manager.* options declared under ./modules/darwin/home-manager.nix.
        home-manager.darwinModules.home-manager
      ];
    };
  };
}
