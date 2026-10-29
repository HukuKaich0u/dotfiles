{pkgs, ...}: {
  home.packages = with pkgs; [
    ast-grep
    awscli2
    bat
    clang-tools
    dotenvx
    ffmpeg
    fzf
    git
    fd
    ghostscript
    gnumake
    google-cloud-sdk
    herdr
    imagemagick
    just
    lazydocker
    lazygit
    lua-language-server
    luarocks
    nodejs_24
    pipx
    pkg-config
    pnpm
    poppler-utils
    postgresql_17
    prek
    ripgrep
    tectonic
    # imozuru の OCR が日本語の横書きと縦書きも読めるよう、言語データを絞って入れる。
    (tesseract.override {enableLanguages = ["eng" "jpn" "jpn_vert"];})
    tmux
    tombi
    tree
    tree-sitter
    uv
    yt-dlp
  ];
}
