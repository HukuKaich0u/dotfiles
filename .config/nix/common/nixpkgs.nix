{
  nixpkgs.config = {
    allowUnfree = true;
  };
  nixpkgs.overlays = [
    (import ./direnv-no-zsh-check-overlay.nix)
  ];
}
