{
  # Homebrew stays responsible for dependency resolution.
  # Keep the top-level packages that are intentionally present on this Mac here.
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    onActivation.extraFlags = [ "--force-cleanup" ];

    taps = [];

    brews = [
      "aom"
      "awscli"
      "dnsmasq"
      "gauche"
      "git-gui"
      "glib"
      "gnu-time"
      "herdr"
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
