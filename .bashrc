# =============================================================================
# ~/.bashrc  —  interactive bash config (primary: remote Linux servers / HPC)
# -----------------------------------------------------------------------------
# Mirrors ~/.zshrc as closely as bash allows, so your remote shells feel like
# your local one. The portable bits come from ~/.shell_common.sh.
# =============================================================================

# If not running interactively, set PATH essentials (so scripts/scp still work)
# then bail out before doing prompt/aliases work.
if [ -n "$HOME/.local/bin" ]; then
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
fi
case $- in
  *i*) ;;            # interactive: keep going
  *) return ;;       # non-interactive: stop here
esac

# --- History (bash) -----------------------------------------------------------
HISTFILE="$HOME/.bash_history"
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth:erasedups     # ignore dups + space-prefixed; prune old dups
HISTTIMEFORMAT='%F %T '              # timestamp each entry
shopt -s histappend                  # append instead of overwriting on exit
# Note: PROMPT_COMMAND is set in .shell_common.sh after tools (zoxide, starship)
# are initialized, so we don't conflict with their hooks here.

# --- Shell behavior -----------------------------------------------------------
shopt -s checkwinsize                # keep $LINES/$COLUMNS correct after resize
shopt -s cdspell                     # autocorrect minor cd typos
shopt -s autocd 2>/dev/null          # bash >=4: type a dir name to cd
shopt -s globstar 2>/dev/null        # ** recursive globbing
shopt -s nocaseglob                  # case-insensitive globbing

# --- Programmable completion --------------------------------------------------
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# --- Shared config (aliases, functions, PATH, conda/fzf/zoxide/starship) -----
[ -f "$HOME/.shell_common.sh" ] && source "$HOME/.shell_common.sh"

# --- Prompt -------------------------------------------------------------------
# starship (loaded in .shell_common.sh) takes over if installed. This is the
# fallback prompt for bare servers: shows conda env, user@host, cwd, git branch,
# and turns the prompt symbol red on a non-zero exit code.
if ! command -v starship >/dev/null 2>&1; then
  __git_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/.*/ (&)/'
  }
  __conda_env() {
    [ -n "$CONDA_DEFAULT_ENV" ] && printf '(%s) ' "$CONDA_DEFAULT_ENV"
  }
  # Colors: green env, bold-blue cwd, yellow git, host shown only over SSH.
  __host_tag=""
  [ -n "$SSH_CONNECTION" ] && __host_tag='\[\e[0;36m\]\u@\h\[\e[0m\]:'
  __set_prompt() {
    local ec=$?
    local sym='$'
    local symcol='\[\e[0;32m\]'
    [ $ec -ne 0 ] && symcol='\[\e[0;31m\]'
    PS1="\[\e[0;32m\]$(__conda_env)\[\e[0m\]${__host_tag}\[\e[1;34m\]\w\[\e[0;33m\]$(__git_branch)\[\e[0m\]\n${symcol}${sym}\[\e[0m\] "
  }
  # Set PROMPT_COMMAND for history sync + custom prompt.
  # Append __set_prompt only if PROMPT_COMMAND is not already set (by zoxide/etc).
  if [ -z "$PROMPT_COMMAND" ]; then
    PROMPT_COMMAND="history -a; history -n; __set_prompt"
  else
    # zoxide or another tool already set PROMPT_COMMAND; prepend history ops
    PROMPT_COMMAND="history -a; history -n; __set_prompt; $PROMPT_COMMAND"
  fi
fi

# --- Machine-local overrides (NOT tracked in git) ----------------------------
[ -f "$HOME/.bashrc.local" ] && source "$HOME/.bashrc.local"
