{
  # Homebrew stays responsible for dependency resolution.
  # Keep the top-level packages that are intentionally present on this Mac here.
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    onActivation.extraFlags = ["--force-cleanup"];

    taps = [];

    brews = [
      "aom"
      "dnsmasq"
      "git-gui"
      "glib"
      "jpeg-xl"
      "libheif"
      "liblqr"
      "libraw"
      "libtiff"
      "terminal-notifier"
    ];

    casks = [
      "codex"
      "cmux"
      "drawio"
      "ghostty"
      "github"
      "ngrok"
      "utm"
      "visual-studio-code"
      "wezterm@nightly"
    ];
  };
}
