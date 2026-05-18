#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_default_nix="$repo_root/nix/modules/home/default.nix"
darwin_default_nix="$repo_root/nix/modules/darwin/default.nix"
linux_default_nix="$repo_root/nix/modules/linux/default.nix"
linux_zsh_nix="$repo_root/nix/modules/linux/zsh.nix"
starship_nix="$repo_root/nix/modules/home/programs/starship.nix"
zsh_nix="$repo_root/nix/modules/home/programs/zsh.nix"
install_script="$repo_root/install.sh"
linux_zsh_dir="$repo_root/zsh"

assert_contains() {
    file="$1"
    pattern="$2"
    message="$3"

    if ! grep -Fq "$pattern" "$file"; then
        echo "$message"
        exit 1
    fi
}

assert_not_contains() {
    file="$1"
    pattern="$2"
    message="$3"

    if grep -Fq "$pattern" "$file"; then
        echo "$message"
        exit 1
    fi
}

assert_missing() {
    path="$1"
    message="$2"

    if [ -e "$path" ] || [ -L "$path" ]; then
        echo "$message"
        exit 1
    fi
}

first_lineno() {
    file="$1"
    pattern="$2"
    grep -nF "$pattern" "$file" | head -n 1 | cut -d: -f1
}

assert_not_contains "$home_default_nix" "./programs/zsh.nix" \
    "modules/home/default.nix should not import programs/zsh.nix once Linux splits off file-based zsh config"
assert_contains "$home_default_nix" "./programs/starship.nix" \
    "modules/home/default.nix should import programs/starship.nix"
assert_contains "$darwin_default_nix" "../home/programs/zsh.nix" \
    "modules/darwin/default.nix should import the Home Manager zsh module for macOS"
assert_contains "$linux_default_nix" "./zsh.nix" \
    "modules/linux/default.nix should import the Linux zsh file-distribution module"

if [ ! -f "$starship_nix" ]; then
    echo "starship.nix should exist"
    exit 1
fi

if [ ! -f "$zsh_nix" ]; then
    echo "zsh.nix should exist"
    exit 1
fi

if [ ! -f "$linux_zsh_nix" ]; then
    echo "linux zsh module should exist"
    exit 1
fi

if [ ! -f "$linux_zsh_dir/.zshenv" ] || [ ! -f "$linux_zsh_dir/.zprofile" ] || [ ! -f "$linux_zsh_dir/.zshrc" ]; then
    echo "repo-root zsh templates should exist for Linux"
    exit 1
fi

if ! nix-instantiate --parse "$zsh_nix" >/dev/null; then
    echo "zsh.nix should parse as valid Nix"
    exit 1
fi

if ! nix-instantiate --parse "$linux_zsh_nix" >/dev/null; then
    echo "linux zsh module should parse as valid Nix"
    exit 1
fi

assert_contains "$zsh_nix" 'programs.zsh = {' \
    "zsh.nix should configure programs.zsh"
assert_contains "$zsh_nix" 'dotDir = zshDotDir;' \
    "zsh.nix should route zsh through dotDir"
assert_not_contains "$zsh_nix" 'home.file.".config/zsh/env.zsh"' \
    "zsh.nix should not materialize a separate env.zsh file anymore"
assert_contains "$zsh_nix" 'autosuggestion.enable = true;' \
    "zsh.nix should enable autosuggestions through Home Manager"
assert_contains "$zsh_nix" 'syntaxHighlighting.enable = true;' \
    "zsh.nix should enable syntax highlighting through Home Manager"
assert_contains "$zsh_nix" 'shellAliases = {' \
    "zsh.nix should manage aliases through programs.zsh.shellAliases"
assert_contains "$zsh_nix" 'nv = "nvim";' \
    "zsh.nix should keep core shell aliases"
assert_contains "$zsh_nix" 'autoload -Uz compinit' \
    "zsh.nix should inline completion initialization"
assert_contains "$zsh_nix" "bindkey '^[^M' self-insert-unmeta" \
    "zsh.nix should keep the multiline input bindkey in initContent"
assert_contains "$zsh_nix" "bindkey -e" \
    "zsh.nix should explicitly enable emacs keybindings for interactive shells"
assert_contains "$zsh_nix" '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' \
    "zsh.nix should source nix-daemon.sh on macOS when available"
assert_contains "$zsh_nix" 'for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do' \
    "zsh.nix should inline Homebrew shellenv lookup"
assert_contains "$zsh_nix" "profileExtra = ''" \
    "zsh.nix should keep environment initialization in profileExtra"
assert_contains "$zsh_nix" 'if [ -f "$HOME/.cargo/env" ]; then' \
    "zsh.nix should own cargo PATH initialization"
assert_contains "$zsh_nix" 'path_prepend_if_dir "$HOME/.npm-global/bin"' \
    "zsh.nix should own the npm-global base path layer"
assert_not_contains "$zsh_nix" 'path_prepend_if_dir "$HOME/.local/bin"' \
    "zsh.nix should not add ~/.local/bin when those tools are unmanaged"
assert_not_contains "$zsh_nix" 'path_append_if_dir "/usr/local/bin"' \
    "zsh.nix should rely on system path setup instead of appending /usr/local/bin manually"
assert_not_contains "$zsh_nix" 'path_append_if_dir "/usr/.local/bin"' \
    "zsh.nix should not append unused local system bin paths manually"
assert_contains "$zsh_nix" 'if [ -d "$HOME/Library/pnpm" ]; then' \
    "zsh.nix should own pnpm PATH initialization"
assert_contains "$zsh_nix" 'if [ -x "$HOME/miniconda3/bin/conda" ]; then' \
    "zsh.nix should own conda PATH initialization"
assert_contains "$zsh_nix" 'if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi' \
    "zsh.nix should own gcloud PATH initialization"
assert_not_contains "$zsh_nix" 'if [ -f "$HOME/.local/bin/env" ]; then' \
    "zsh.nix should not source ~/.local/bin/env once local bin helpers are removed"
assert_not_contains "$zsh_nix" 'nix > homebrew' \
    "zsh.nix should not claim strict nix-over-homebrew PATH ordering anymore"
assert_contains "$zsh_nix" 'export ZSH_STATE_DIR="'"''"'${XDG_STATE_HOME:-$HOME/.local/state}/zsh"' \
    "zsh.nix should own the zsh state directory setup"
assert_contains "$zsh_nix" 'export BAT_THEME="1337"' \
    "zsh.nix should export the shared bat theme"
assert_contains "$zsh_nix" 'export HISTFILE="$ZSH_STATE_DIR/.zsh_history"' \
    "zsh.nix should own the zsh history file setup"
assert_not_contains "$zsh_nix" '/opt/homebrew/opt/openjdk' \
    "zsh.nix should no longer contain Homebrew openjdk initialization"
assert_contains "$zsh_nix" 'export CPLUS_INCLUDE_PATH="'"''"'${CPLUS_INCLUDE_PATH:+$CPLUS_INCLUDE_PATH:}$HOME/include"' \
    "zsh.nix should own CPLUS_INCLUDE_PATH initialization"
assert_contains "$zsh_nix" 'export PNPM_HOME="$HOME/Library/pnpm"' \
    "zsh.nix should own PNPM_HOME initialization"
assert_contains "$zsh_nix" 'if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi' \
    "zsh.nix should own gcloud completion initialization"
assert_not_contains "$zsh_nix" 'source "$ZDOTDIR/homebrew.zsh"' \
    "zsh.nix should not depend on a separate homebrew.zsh file anymore"
assert_not_contains "$zsh_nix" 'source "$ZDOTDIR/env.zsh"' \
    "zsh.nix should not depend on a separate env.zsh file anymore"
assert_contains "$starship_nix" 'programs.starship = {' \
    "starship.nix should configure programs.starship"
assert_contains "$starship_nix" 'enable = true;' \
    "starship.nix should enable starship through Home Manager"
assert_contains "$starship_nix" 'settings = {' \
    "starship.nix should generate starship config from settings"
assert_contains "$starship_nix" 'docker_context = {' \
    "starship.nix should keep the custom docker context module"
assert_missing "$repo_root/.config/starship.toml" \
    "repo root should not keep a hand-managed starship.toml source"

assert_contains "$linux_zsh_nix" 'home.file.".zshenv"' \
    "linux zsh module should install ~/.zshenv directly"
assert_contains "$linux_zsh_nix" 'home.file.".zprofile"' \
    "linux zsh module should install ~/.zprofile directly"
assert_contains "$linux_zsh_nix" 'home.file.".zshrc"' \
    "linux zsh module should install ~/.zshrc directly"
assert_contains "$linux_zsh_nix" '../../../zsh/.zshenv' \
    "linux zsh module should read the repo-root .zshenv template"
assert_contains "$linux_zsh_nix" '../../../zsh/.zprofile' \
    "linux zsh module should read the repo-root .zprofile template"
assert_contains "$linux_zsh_nix" '../../../zsh/.zshrc' \
    "linux zsh module should read the repo-root .zshrc template"
assert_contains "$linux_zsh_nix" 'replaceVars' \
    "linux zsh module should use replaceVars for template substitution"
assert_not_contains "$linux_zsh_nix" 'substituteAll' \
    "linux zsh module should not use removed substituteAll"
assert_contains "$linux_zsh_nix" 'zsh-autosuggestions' \
    "linux zsh module should still install zsh autosuggestions explicitly"
assert_contains "$linux_zsh_nix" 'zsh-syntax-highlighting' \
    "linux zsh module should still install zsh syntax highlighting explicitly"
assert_contains "$linux_zsh_dir/.zshrc" 'autoload -Uz compinit' \
    "linux zshrc template should initialize completion"
assert_contains "$linux_zsh_dir/.zprofile" 'if [ -f "$HOME/.cargo/env" ]; then' \
    "linux zsh profile template should initialize cargo for login shells"
assert_contains "$linux_zsh_dir/.zprofile" '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' \
    "linux zsh profile template should source nix-daemon.sh when available"
assert_contains "$linux_zsh_dir/.zprofile" 'if [ -d "$HOME/.local/share/pnpm" ]; then' \
    "linux zsh profile template should initialize pnpm for login shells"
assert_contains "$linux_zsh_dir/.zprofile" 'if [ -x "$HOME/miniconda3/bin/conda" ]; then' \
    "linux zsh profile template should initialize conda for login shells"
assert_contains "$linux_zsh_dir/.zprofile" 'if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi' \
    "linux zsh profile template should initialize gcloud path for login shells"
assert_contains "$linux_zsh_dir/.zshenv" 'export BAT_THEME="1337"' \
    "linux zsh env template should export the shared bat theme"
assert_contains "$linux_zsh_dir/.zshrc" 'eval "$(starship init zsh)"' \
    "linux zshrc template should initialize starship without programs.zsh"
assert_contains "$linux_zsh_dir/.zshrc" 'eval "$(mise activate zsh)"' \
    "linux zshrc template should initialize mise without programs.zsh"
assert_not_contains "$linux_zsh_dir/.zshrc" '$HOME/.cargo/env' \
    "linux zshrc template should no longer initialize cargo in interactive-only config"
assert_not_contains "$linux_zsh_dir/.zshrc" '$HOME/.local/share/pnpm' \
    "linux zshrc template should no longer initialize pnpm in interactive-only config"
assert_not_contains "$linux_zsh_dir/.zshrc" 'miniconda3/bin/conda' \
    "linux zshrc template should no longer initialize conda in interactive-only config"
assert_not_contains "$linux_zsh_dir/.zshrc" 'path.zsh.inc' \
    "linux zshrc template should no longer initialize gcloud path in interactive-only config"
assert_not_contains "$linux_zsh_dir/.zshrc" '/opt/homebrew/bin/brew' \
    "linux zshrc template should not contain Homebrew initialization"

init_content_line="$(first_lineno "$zsh_nix" 'initContent = lib.mkMerge')"
path_helper_line="$(first_lineno "$zsh_nix" 'path_prepend_if_dir()')"
state_dir_line="$(first_lineno "$zsh_nix" 'export ZSH_STATE_DIR=')"

if [ -z "$init_content_line" ] || [ -z "$path_helper_line" ] || [ -z "$state_dir_line" ]; then
    echo "zsh.nix should keep initContent and environment initialization markers"
    exit 1
fi

if [ "$path_helper_line" -gt "$init_content_line" ]; then
    echo "zsh.nix should initialize PATH before initContent begins"
    exit 1
fi

if [ "$state_dir_line" -gt "$init_content_line" ]; then
    echo "zsh.nix should initialize env vars before initContent begins"
    exit 1
fi

assert_contains "$install_script" 'HOME_DOTFILES=""' \
    "install.sh should stop linking zsh dotfiles"
assert_contains "$install_script" 'SKIP_CONFIG_DIRS="tmux zsh starship.toml yazi bacon wezterm nvim"' \
    "install.sh should stop linking .config/zsh and starship.toml"

assert_missing "$repo_root/.zshenv" \
    "repo root should not keep a hand-managed top-level .zshenv entrypoint"
assert_missing "$repo_root/.zprofile" \
    "repo root should not keep a hand-managed top-level .zprofile entrypoint"
assert_missing "$repo_root/.zshrc" \
    "repo root should not keep a hand-managed top-level .zshrc entrypoint"

echo "zsh nix migration tests passed"
