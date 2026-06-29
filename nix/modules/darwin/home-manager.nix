{
  self,
  agentKitSrc,
  ...
}: {
  # This file is only the connection layer from nix-darwin into the existing
  # Home Manager tree. Put actual user-facing config such as shell, git, tmux,
  # and other daily tools under ../home/default.nix and its imports.

  # Reuse the same nixpkgs set on both sides so darwin and Home Manager do not
  # drift onto different package revisions.
  home-manager.useGlobalPkgs = true;
  # Let Home Manager install packages for the user through the darwin
  # integration instead of treating it as a completely separate setup.
  home-manager.useUserPackages = true;
  # darwin's specialArgs only reach the darwin module tree, not the nested
  # home-manager modules. Forward what those modules require (e.g. agentKitSrc
  # consumed by agent-skills/*.nix) via extraSpecialArgs so they evaluate.
  home-manager.extraSpecialArgs = {inherit self agentKitSrc;};
  # The real Home Manager module tree starts here.
  home-manager.users."KokiAoyagi" = ./default.nix;
}
