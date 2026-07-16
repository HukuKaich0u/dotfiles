let
  flake = builtins.getFlake (toString ../nix);

  standaloneTargets = builtins.attrNames flake.homeConfigurations.kokiaoyagi.config.home.file;
  darwinTargets = builtins.attrNames flake.darwinConfigurations.KokiAoyagi.config.home-manager.users.KokiAoyagi.home.file;

  containsKeyBindDoc = target: builtins.match ".*key-bind\\.md.*" target != null;
  isHerdrTarget = target: builtins.match ".*\\.config/herdr(/.*)?$" target != null;
  isHerdrConfig = target: builtins.match ".*\\.config/herdr/config\\.toml$" target != null;

  assertTargetSet = name: targets:
    let
      deployedKeyBindDocs = builtins.filter containsKeyBindDoc targets;
      herdrTargets = builtins.filter isHerdrTarget targets;
    in
      if deployedKeyBindDocs != []
      then throw "${name} must not deploy repository-only key-bind.md targets: ${builtins.toJSON deployedKeyBindDocs}"
      else if builtins.length herdrTargets != 1 || !isHerdrConfig (builtins.head herdrTargets)
      then throw "${name} must deploy only .config/herdr/config.toml under .config/herdr; found ${builtins.toJSON herdrTargets}"
      else true;
in
  assertTargetSet "standalone Home Manager" standaloneTargets
  && assertTargetSet "nix-darwin Home Manager" darwinTargets
