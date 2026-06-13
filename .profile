# =============================================================================
# ~/.profile  —  POSIX login fallback (sh/dash, or bash without .bash_profile)
# -----------------------------------------------------------------------------
# Keep this strictly POSIX (no bash/zsh-isms): some HPC login managers and
# /bin/sh contexts read this. Only PATH-level essentials go here.
# =============================================================================

# User-local binaries
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/bin" ]        && PATH="$HOME/bin:$PATH"
export PATH

# If this is bash, hand off to .bashrc for the interactive goodies.
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi
