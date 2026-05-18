{
  # Homebrew stays responsible for dependency resolution.
  # Keep the top-level packages that are intentionally present on this Mac here.
  homebrew = {
    enable = true;

    taps = [
      "k1low/tap"
      "oven-sh/bun"
      "steipete/tap"
      "thezoraiz/ascii-image-converter"
      "trasta298/tap"
    ];

    brews = [
      "aom"
      "dnsmasq"
      "gauche"
      "gcc"
      "git-gui"
      "glib"
      "gnu-time"
      "jpeg-xl"
      "k1low/tap/mo"
      "libheif"
      "liblqr"
      "libraw"
      "libtiff"
      "llvm"
      "lua"
      "marp-cli"
      "oven-sh/bun/bun"
      "php"
      "prek"
      "qemu"
      "terminal-notifier"
    ];

    casks = [
      "codex"
      "cursor-cli"
      "gcloud-cli"
      "ghostty"
      "github"
      "ngrok"
      "rectangle"
      "utm"
      "visual-studio-code"
      "wezterm@nightly"
    ];
  };
}
