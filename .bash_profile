# =============================================================================
# ~/.bash_profile  —  bash LOGIN shells
# -----------------------------------------------------------------------------
# Login bash reads .bash_profile (NOT .bashrc). The near-universal convention
# is to have it simply source .bashrc so login and non-login interactive shells
# behave identically. This is what makes `ssh server` give you the same setup
# as opening a new pane.
# =============================================================================

# Source the POSIX-level profile first (PATH for login shells), if present.
[ -f "$HOME/.profile" ] && . "$HOME/.profile"

# Then the full interactive bash config.
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
