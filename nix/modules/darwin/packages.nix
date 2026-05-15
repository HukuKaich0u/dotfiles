{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    pngpaste
    pkgs."ascii-image-converter"
  ];
}
