{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    awscli2
    # macOS では Homebrew brew で入れている herdr を、Linux では nixpkgs で持つ。
    herdr
  ];
}
