{pkgs, ...}: {
  home.packages = with pkgs; [
    # ホスト側の build-essential / Docker は apt で管理する。
  ];
}
