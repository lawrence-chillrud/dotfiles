# =============================================================================
# ~/.zprofile  —  zsh LOGIN shells (read once at login, before ~/.zshrc)
# -----------------------------------------------------------------------------
# This is the correct place for PATH-affecting setup that should run once per
# login, most importantly Homebrew on Apple Silicon. On macOS, iTerm starts
# login shells, so this always runs.
# =============================================================================

# --- Homebrew -----------------------------------------------------------------
# Apple Silicon Homebrew lives in /opt/homebrew; Intel macs use /usr/local.
# `brew shellenv` sets PATH, MANPATH, INFOPATH, HOMEBREW_* correctly.
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Linuxbrew (in case you bootstrap it in your HPC home dir)
[ -x "$HOME/.linuxbrew/bin/brew" ] && eval "$($HOME/.linuxbrew/bin/brew shellenv)"
[ -x /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Machine-local login-time overrides (untracked)
[ -f "$HOME/.zprofile.local" ] && source "$HOME/.zprofile.local"
