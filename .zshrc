# =============================================================================
# ~/.zshrc  —  interactive zsh config (primary: macOS + iTerm + oh-my-zsh)
# -----------------------------------------------------------------------------
# This file is intentionally thin: oh-my-zsh + zsh-specific options live here,
# but everything portable (aliases, functions, PATH, tool init) lives in
# ~/.shell_common.sh so it can be reused by bash on remote servers.
# =============================================================================

# --- oh-my-zsh ----------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"

# Theme: robbyrussell is the safe default that renders on ANY terminal/font.
# If starship is installed (see .shell_common.sh) it takes over the prompt and
# this theme becomes irrelevant — that's fine and intended.
ZSH_THEME="fwalch" # "robbyrussell"

# Plugins. The first row is bundled with oh-my-zsh. The last two
# (autosuggestions, syntax-highlighting) are external and are cloned by
# install.sh; if they're missing oh-my-zsh just skips them with a notice.
plugins=(
  git                         # tons of git aliases + branch completion
  colored-man-pages           # readable man pages
  command-not-found           # suggests the package that provides a missing cmd
  extract                     # `x file.tar.gz` style extraction
  fzf                         # wires up fzf keybindings if fzf is present
  history-substring-search    # type a prefix + Up arrow to search history
  zsh-autosuggestions         # fish-style grey inline suggestions  (external)
  zsh-syntax-highlighting      # red/green command validity coloring (external)
)

# Only source oh-my-zsh if it's actually installed (it won't be on a fresh HPC
# node where you might still use zsh manually).
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# --- History (zsh) ------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY          # record timestamp of each command
setopt SHARE_HISTORY             # share history live across all open shells
setopt INC_APPEND_HISTORY        # write as you go, not just on exit
setopt HIST_IGNORE_ALL_DUPS      # collapse duplicate commands
setopt HIST_IGNORE_SPACE         # a leading space hides a command from history
setopt HIST_REDUCE_BLANKS        # tidy up whitespace
setopt HIST_VERIFY               # let you edit a !history expansion before running

# --- Navigation & completion quality-of-life ---------------------------------
setopt AUTO_CD                   # type a dir name to cd into it
setopt AUTO_PUSHD                # cd maintains a stack; use `cd -<TAB>`
setopt PUSHD_IGNORE_DUPS
setopt CORRECT                   # offer to correct mistyped commands
setopt INTERACTIVE_COMMENTS      # allow # comments in interactive shell
setopt NO_BEEP

# Better completion menu (oh-my-zsh sets up compinit; these refine it)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' menu select                          # arrow-key menu
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"     # colorize matches

# history-substring-search arrow bindings (works whether or not omz loaded it)
bindkey '^[[A' history-substring-search-up 2>/dev/null
bindkey '^[[B' history-substring-search-down 2>/dev/null

# --- Shared config (aliases, functions, PATH, conda/fzf/zoxide/starship) -----
[ -f "$HOME/.shell_common.sh" ] && source "$HOME/.shell_common.sh"

# --- Machine-local overrides (NOT tracked in git) ----------------------------
# Put host-specific secrets/paths/module loads here. Create it per-machine.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
