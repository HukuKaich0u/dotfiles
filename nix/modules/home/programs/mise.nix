{lib, ...}: {
  programs.mise.enable = true;
  # shell-integrations.nix で事前生成した hook を読み込む。
  programs.mise.enableBashIntegration = false;
  programs.mise.enableZshIntegration = false;
  programs.mise.globalConfig = {
    tools = {
      bun = "1.3.14";
      go = "1.26.6";
      java = "25.0.2";
      lua = "5.4.8";
      terraform = "1.12.2";
    };
    settings = {};
  };

  home.sessionVariables = {
    # Work around asdf-lua failing to bootstrap with the latest LuaRocks release.
    ASDF_LUA_LUAROCKS_VERSION = "3.12.2";
  };

  # 旧 activation が作った mise Node 依存の shim だけを外す。
  # 独自の executable や別の管理元への symlink は変更しない。
  home.activation.removeLegacyCorepackShims = lib.hm.dag.entryAfter ["writeBoundary"] ''
    for tool in pnpm pnpx yarn yarnpkg; do
      shim="$HOME/.local/bin/$tool"
      if [ -L "$shim" ]; then
        case "$(readlink "$shim")" in
          ../share/mise/installs/node/*/lib/node_modules/corepack/dist/"$tool".js|"$HOME"/.local/share/mise/installs/node/*/lib/node_modules/corepack/dist/"$tool".js)
            rm "$shim"
            ;;
        esac
      fi
    done
  '';
}
