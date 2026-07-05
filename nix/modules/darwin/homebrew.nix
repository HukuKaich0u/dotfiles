{
  # Homebrew stays responsible for dependency resolution.
  # Keep the top-level packages that are intentionally present on this Mac here.
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    onActivation.extraFlags = [ "--force-cleanup" ];

    taps = [
      "steipete/tap"
      "thezoraiz/ascii-image-converter"
      "trasta298/tap"
    ];

    brews = [
      "aom"
      "awscli"
      "dnsmasq"
      "gauche"
      "gcc"
      "git-gui"
      "glib"
      "gnu-time"
      "jpeg-xl"
      "libheif"
      "liblqr"
      "libraw"
      "libtiff"
      "llvm"
      "marp-cli"
      "php"
      "prek"
      "qemu"
      "terminal-notifier"
    ];

    casks = [
      "codex"
      "cmux"
      "drawio"
      "gcloud-cli"
      "github"
      "ngrok"
      "utm"
      "visual-studio-code"
      "wezterm@nightly"
    ];
  };
}
