{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../home/default.nix
    ../home/programs/wezterm.nix
    ../home/programs/zsh.nix
    ./packages.nix
  ];

  home.username = "KokiAoyagi";
  home.homeDirectory = "/Users/KokiAoyagi";

  # home-manager / nix profile の古い世代を消す。root 側の GC
  # (./system.nix) は ~/.local/state 配下の世代に触れない。
  nix.gc = {
    automatic = true;
    dates = "weekly";
  };
  # Home Manager の darwin 実装は nix.gc.options を 1 つの argv 要素として
  # 渡すため、"--delete-older-than 30d" が unrecognised flag で失敗する。
  # 引数を分けた ProgramArguments で上書きする。
  launchd.agents.nix-gc.config.ProgramArguments = lib.mkForce [
    "${pkgs.nix}/bin/nix-collect-garbage"
    "--delete-older-than"
    "30d"
  ];
}
