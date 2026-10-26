{
  # Homebrew stays responsible for dependency resolution.
  # Keep the top-level packages that are intentionally present on this Mac here.
  homebrew = {
    enable = true;
    # Without these, switch only installs missing entries and never runs
    # `brew update` or upgrades what is already installed.
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
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
      "markdown-preview"
      "ngrok"
      "utm"
      "visual-studio-code"
      "wezterm@nightly"
    ];
  };
}
