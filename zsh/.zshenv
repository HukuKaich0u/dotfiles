# Linux zsh entrypoint distributed by Home Manager without enabling programs.zsh.

if [ -z "$__HM_ZSH_SESS_VARS_SOURCED" ]; then
    for hm_session_vars in \
        "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" \
        "$HOME/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh" \
        "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"; do
        if [ -f "$hm_session_vars" ]; then
            . "$hm_session_vars"
            export __HM_ZSH_SESS_VARS_SOURCED=1
            break
        fi
    done
fi

export ZSH_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
mkdir -p "$ZSH_STATE_DIR"
export BAT_THEME="1337"
export HISTFILE="$ZSH_STATE_DIR/.zsh_history"
