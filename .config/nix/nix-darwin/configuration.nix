{self, ...}: {
  # 後方互換性のための値、nix-darwin本体のバージョン依存
  # 原則、各自がインストールした際に設定した値のままにしてください
  system.stateVersion = 6;

  # ビルド時の設定ファイルのコミット位置を記録
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Mac本体のユーザー設定を変更する際に必要
  system.primaryUser = "KokiAoyagi";

  # ホームディレクトリを指定
  users.users.KokiAoyagi.home = "/Users/KokiAoyagi/";

  # nix-darwinによる Nix の管理を無効化
  nix.enable = false;

  # 利用するシェルを指定する
  programs.zsh.enable = true;

  system.defaults = {
    NSGlobalDomain = {
      # マウス・トラックパッド
      "com.apple.swipescrolldirection" = true; # ナチュラルスクロールを有効化

      # キーボード
      NSAutomaticCapitalizationEnabled = false; # 文頭の自動大文字化を無効化
      NSAutomaticPeriodSubstitutionEnabled = false; # ピリオドの自動置換を無効化
      NSAutomaticSpellingCorrectionEnabled = false; # スペル自動修正を無効化
      NSAutomaticDashSubstitutionEnabled = false; # ダッシュの自動置換を無効化
      NSAutomaticQuoteSubstitutionEnabled = false; # クォートの自動置
    };

    finder = {
      AppleShowAllExtensions = true; # ファイル拡張子を常に表示
      AppleShowAllFiles = true; # 隠しファイルを表示
      FXDefaultSearchScope = "SCcf"; # 検索範囲をカレントフォルダに設定
      ShowPathbar = true; # パスバーを表示
      FXEnableExtensionChangeWarning = false; # ファイル拡張子変更の警告を無効化
      FXPreferredViewStyle = "Nlsv"; # デフォルトの表示方法をリストビューに設定
    };

    dock = {
      show-process-indicators = true; # 起動中アプリをインジケーターに表示
      show-recents = false; # 最近使ったアプリを非表示
      launchanim = false; # アプリ起動時のアニメーションを無効化
      mineffect = "scale"; # ウィンドウを閉じるときのエフェクトをスケールに設定
    };

    CustomUserPreferences = {
      NSGlobalDomain = {
        # キーボード
        WebAutomaticSpellingCorrectionEnabled = false; # スペル自動修正を無効化 (WebView)
        # Finder
        AppleMenuBarVisibleInFullscreen = true; # フルスクリーン時にメニューバーを表示
      };
    };
  };
  nixpkgs.hostPlatform = "aarch64-darwin";
  security.pam.services.sudo_local.touchIdAuth = true;
}
