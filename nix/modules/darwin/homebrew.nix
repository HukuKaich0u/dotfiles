{
  # Homebrew stays responsible for dependency resolution.
  # Keep the top-level packages that are intentionally present on this Mac here.
  homebrew = {
    enable = true;
    # switch は一覧にあって未導入のものを入れ、一覧に無いものを外すだけにする。
    # Homebrew 本体と導入済みの formula / cask は switch では更新しないので、
    # `brew update && brew upgrade` を手動で実行する。
    onActivation.cleanup = "uninstall";
    onActivation.extraFlags = [ "--force-cleanup" ];

    taps = [ ];

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
