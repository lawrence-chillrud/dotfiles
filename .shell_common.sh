# =============================================================================
# ~/.shell_common.sh
# -----------------------------------------------------------------------------
# Shared configuration sourced by BOTH ~/.zshrc (local macOS) and ~/.bashrc
# (remote Linux / HPC). Keep everything here POSIX-ish or guarded by shell
# detection so the SAME behavior follows you onto every machine you ssh into.
#
# Nothing here should depend on a tool actually being installed: every
# integration is guarded by `command -v`, so this file is safe to source on a
# bare HPC login node with nothing but stock bash.
# =============================================================================

# --- Shell detection ---------------------------------------------------------
# Lets blocks below branch on zsh vs bash without re-checking everywhere.
if [ -n "$ZSH_VERSION" ]; then
  CURRENT_SHELL="zsh"
elif [ -n "$BASH_VERSION" ]; then
  CURRENT_SHELL="bash"
else
  CURRENT_SHELL="sh"
fi

# Is this an interactive shell? (skip prompt/tool init in scripts & scp)
case $- in
  *i*) IS_INTERACTIVE=1 ;;
  *)   IS_INTERACTIVE=0 ;;
esac

# --- PATH management ----------------------------------------------------------
# Idempotent prepend: never adds a dir twice, so re-sourcing is harmless.
path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;                       # already present, do nothing
    *) [ -d "$1" ] && PATH="$1:$PATH" ;;
  esac
}

path_prepend "$HOME/.local/bin"        # pip --user / pipx installs land here
path_prepend "$HOME/bin"               # your own one-off scripts
path_prepend "$HOME/.cargo/bin"        # rust tools (delta, ripgrep if cargo-installed)
export PATH

# --- Core environment ---------------------------------------------------------
export EDITOR="vim"
export VISUAL="$EDITOR"
export PAGER="less"
# -R: render colors, -F: quit if one screen, -X: don't clear screen, -i: smart-case search
export LESS="-RFXi"
export LANG="${LANG:-en_US.UTF-8}"     # HPC nodes often ship with no locale set
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# Make Python behave well in research workflows
export PYTHONDONTWRITEBYTECODE=1       # no stray __pycache__ in your repos
export PIP_REQUIRE_VIRTUALENV=false    # set true if you NEVER want pip in base

# Bigger, smarter history is shared in the shell-specific rc files (zsh/bash
# differ too much), but the history FILE locations are set here for parity.
export HISTSIZE=100000

# --- "Modern Unix" tool swaps (only if installed) ----------------------------
# ls -> eza (falls back to coreutils/BSD ls flavor automatically)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lhg --group-directories-first --git'
  alias la='eza -lahg --group-directories-first --git'
  alias lt='eza --tree --level=2 --group-directories-first'
elif command -v exa >/dev/null 2>&1; then
  alias ls='exa --group-directories-first'
  alias ll='exa -lhg --group-directories-first --git'
  alias la='exa -lahg --group-directories-first --git'
  alias lt='exa --tree --level=2'
else
  # Plain ls: GNU (Linux) supports --color, BSD/macOS uses -G
  if ls --color=auto >/dev/null 2>&1; then
    alias ls='ls --color=auto --group-directories-first'
  else
    alias ls='ls -G'
  fi
  alias ll='ls -lh'
  alias la='ls -lah'
fi

# cat -> bat (note: Debian/Ubuntu ship it as `batcat`)
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  export BAT_THEME="ansi"
elif command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --paging=never'
  alias bat='batcat'
  export BAT_THEME="ansi"
fi

# grep/find -> ripgrep/fd if present (kept as separate names so muscle memory
# for plain grep/find still works on machines that lack them)
command -v rg >/dev/null 2>&1 && alias rgi='rg -i'
if command -v fd >/dev/null 2>&1; then :; elif command -v fdfind >/dev/null 2>&1; then alias fd='fdfind'; fi

# Always-safe color for grep on any platform
alias grep='grep --color=auto'

# --- General aliases ----------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'                      # `-` jumps to previous dir
alias mkdir='mkdir -p'
alias df='df -h'
alias du='du -h'
alias free='free -h 2>/dev/null || vm_stat'   # free is Linux-only
alias path='echo -e "${PATH//:/\\n}"'  # print PATH one entry per line
alias reload='exec $SHELL -l'          # reload the shell after editing dotfiles
alias h='history'
alias c='clear'

# Interactive-by-default for destructive ops (override with \cp etc.)
alias cp='cp -i'
alias mv='mv -i'
# NOTE: `rm` is deliberately NOT aliased to `rm -i`. On HPC you'll routinely
# rm large result dirs and an interactive prompt becomes a footgun. Use `trash`
# (see function below) when you want a safety net.

# --- Git aliases (mirror the ones in ~/.gitconfig for shell-level speed) ------
alias g='git'
alias gst='git status -sb'
alias gco='git checkout'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gds='git diff --staged'
alias glog='git log --oneline --graph --decorate -20'
alias gb='git branch'

# --- Python / mamba / conda aliases ------------------------------------------
# `mamba` is preferred; everything falls through to `conda` if mamba is absent.
if command -v mamba >/dev/null 2>&1; then
  CONDA_FRONTEND="mamba"
elif command -v conda >/dev/null 2>&1; then
  CONDA_FRONTEND="conda"
fi
alias py='python'
alias ipy='ipython'
alias jl='jupyter lab'
alias jn='jupyter notebook'
alias act='${CONDA_FRONTEND:-conda} activate'
alias deact='${CONDA_FRONTEND:-conda} deactivate'
alias envs='${CONDA_FRONTEND:-conda} env list'
alias mkenv='${CONDA_FRONTEND:-mamba} create -y -n'   # usage: mkenv myenv python=3.11
# Dump a reproducible, cross-platform env file (no build hashes, with pip deps)
condaexport() {
  local name="${1:-$CONDA_DEFAULT_ENV}"
  [ -z "$name" ] && { echo "usage: condaexport <env-name>"; return 1; }
  ${CONDA_FRONTEND:-conda} env export -n "$name" --no-builds --from-history
}

# --- GPU / ML helpers ---------------------------------------------------------
if command -v nvidia-smi >/dev/null 2>&1; then
  alias gpu='nvidia-smi'
  # Live-updating, compact GPU view. Uses gpustat if available, else nvidia-smi.
  if command -v gpustat >/dev/null 2>&1; then
    alias gpuw='gpustat -i 1 --color'
  else
    alias gpuw='watch -n 1 nvidia-smi'
  fi
  # Just the memory/util numbers, scriptable
  alias gpumem='nvidia-smi --query-gpu=index,name,memory.used,memory.total,utilization.gpu --format=csv'
fi

# --- HPC: SLURM scheduler shortcuts (only defined on SLURM systems) ----------
if command -v squeue >/dev/null 2>&1; then
  alias sq='squeue -u "$USER" -o "%.18i %.9P %.30j %.8T %.10M %.6D %R"'   # my jobs, readable
  alias sqa='squeue -o "%.18i %.9P %.20j %.8u %.8T %.10M %.6D %R"'        # all jobs
  alias si='sinfo -o "%20P %5a %.10l %16F %N"'                            # partition/node summary
  alias scq='scancel -u "$USER"'                                          # cancel ALL my jobs (careful!)
  # Interactive node grabber — EDIT the defaults to match your cluster.
  alias interactive='srun --pty --partition=gpu --gres=gpu:1 --cpus-per-task=8 --mem=32G --time=04:00:00 bash -l'
  # Tail the most recent slurm-*.out in the current dir
  slog() { tail -f "$(ls -t slurm-*.out 2>/dev/null | head -1)"; }
fi
# Lmod / environment-modules: short `ml` already exists on most clusters; alias
# the verbose form just in case it doesn't.
command -v module >/dev/null 2>&1 && ! command -v ml >/dev/null 2>&1 && alias ml='module'

# --- tmux shortcuts -----------------------------------------------------------
if command -v tmux >/dev/null 2>&1; then
  alias t='tmux'
  alias ta='tmux attach -t'
  alias tn='tmux new -s'
  alias tl='tmux ls'
  alias tk='tmux kill-session -t'
fi

# --- opencode (your terminal LLM agent) --------------------------------------
if command -v opencode >/dev/null 2>&1; then
  alias oc='opencode'
  # `ocp` = run opencode rooted at the current project directory
  alias ocp='opencode .'
fi

# --- Useful functions ---------------------------------------------------------
# Make a dir and cd into it
mkcd() { mkdir -p "$1" && cd "$1" || return; }

# Universal archive extractor
extract() {
  [ -f "$1" ] || { echo "extract: '$1' is not a file"; return 1; }
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar)            tar xf  "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.gz)             gunzip  "$1" ;;
    *.zip)            unzip   "$1" ;;
    *.7z)             7z x    "$1" ;;
    *.rar)            unrar x "$1" ;;
    *) echo "extract: don't know how to extract '$1'" ;;
  esac
}

# Soft "trash" instead of rm -rf: moves to ~/.local/share/Trash/<timestamp>
trash() {
  local dest="$HOME/.local/share/Trash/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$dest" && mv "$@" "$dest"/ && echo "moved to $dest"
}

# What's listening on a port?  (port 8888)
port() { lsof -nP -iTCP:"$1" -sTCP:LISTEN 2>/dev/null || ss -ltnp 2>/dev/null | grep ":$1"; }

# Kill whatever is on a port (kport 8888)
kport() { lsof -ti:"$1" 2>/dev/null | xargs -r kill -9; }

# Quick static file server in the current dir (serve [port])
serve() { python -m http.server "${1:-8000}"; }

# fzf-powered: jump to a recently used git repo / dir under ~ (needs fzf+fd)
# Edit the search root to taste.
proj() {
  command -v fzf >/dev/null 2>&1 || { echo "proj needs fzf"; return 1; }
  local finder
  if command -v fd >/dev/null 2>&1; then finder='fd -t d -d 4 . "$HOME/projects" "$HOME/code" "$HOME/work" 2>/dev/null';
  else finder='find "$HOME/projects" "$HOME/code" "$HOME/work" -maxdepth 4 -type d 2>/dev/null'; fi
  local dir; dir="$(eval "$finder" | fzf)" && cd "$dir" || return
}

# =============================================================================
# Tool initialization — INTERACTIVE shells only, all guarded by `command -v`.
# Order matters: conda first, then fzf/zoxide, then starship LAST (it owns the
# prompt and should run after everything else).
# =============================================================================
if [ "$IS_INTERACTIVE" = "1" ]; then

  # --- conda / mamba ----------------------------------------------------------
  # Searches the usual install roots. The first hit wins. miniforge/mambaforge
  # are listed first because that's what you get with a mamba-centric setup.
  # NOTE: this works for both login and non-login (e.g., VS Code) shells because
  # we invoke `mamba shell hook` which fully initializes the shell integration.
  for __conda_root in \
      "$HOME/miniforge3" "$HOME/mambaforge" "$HOME/miniconda3" "$HOME/anaconda3" \
      "/opt/conda" "/opt/miniforge3" "/opt/miniconda3"; do
    if [ -f "$__conda_root/etc/profile.d/conda.sh" ]; then
      . "$__conda_root/etc/profile.d/conda.sh"
      # Initialize mamba as a shell function (much faster solver than plain conda).
      # For non-login shells (like VS Code terminals), we need `mamba shell hook`
      # in addition to sourcing mamba.sh.
      if command -v mamba >/dev/null 2>&1; then
        # Source mamba.sh for compatibility, but suppress errors
        [ -f "$__conda_root/etc/profile.d/mamba.sh" ] && \
          . "$__conda_root/etc/profile.d/mamba.sh" 2>/dev/null || true
        # Run the mamba shell hook for proper initialization in all shell types.
        # Try with the detected shell, fall back to zsh/bash if detection failed.
        eval "$(mamba shell hook --shell "$CURRENT_SHELL" 2>/dev/null)" || \
        eval "$(mamba shell hook --shell zsh 2>/dev/null)" || \
        eval "$(mamba shell hook --shell bash 2>/dev/null)" || true
      fi
      break
    fi
  done
  unset __conda_root

  # --- fzf (fuzzy finder: Ctrl-R history, Ctrl-T files, Alt-C cd) ------------
  if command -v fzf >/dev/null 2>&1; then
    # fzf >= 0.48 ships shell integration via `fzf --<shell>`; fall back to the
    # legacy sourced files for older versions.
    if fzf --"$CURRENT_SHELL" >/dev/null 2>&1; then
      eval "$(fzf --"$CURRENT_SHELL")"
    else
      [ -f ~/.fzf."$CURRENT_SHELL" ] && . ~/.fzf."$CURRENT_SHELL"
    fi
    # Sensible defaults; use fd for the file walker if available.
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"
    command -v fd >/dev/null 2>&1 && export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  fi

  # --- zoxide (smarter cd: `z partial-dir-name`) -----------------------------
  if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init "$CURRENT_SHELL")"
  fi

  # --- starship prompt (cross-shell; overrides the omz theme if installed) ---
  if command -v starship >/dev/null 2>&1; then
    eval "$(starship init "$CURRENT_SHELL")"
  fi

fi
