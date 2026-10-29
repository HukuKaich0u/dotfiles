{pkgs, ...}: {
  home.packages =
    (with pkgs; [
      ax
      mo
      gauche
      llvm
      marp-cli
      php
      pngpaste
      qemu
      time
      pkgs."ascii-image-converter"
    ])
    ++ [
      # Homebrew の gnu-time が提供していた command 名を維持する。
      (pkgs.writeShellScriptBin "gtime" ''
        exec ${pkgs.time}/bin/time "$@"
      '')
    ];
}
