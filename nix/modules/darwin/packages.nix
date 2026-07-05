{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    mo
    pngpaste
    pkgs."ascii-image-converter"
  ];
}
