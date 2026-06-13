#!/usr/bin/env bash
# ============================================================================
# install.sh  —  symlink these dotfiles into $HOME (idempotent, with backups)
# ----------------------------------------------------------------------------
# Usage:
#   ./install.sh              # symlink all dotfiles (backs up any existing ones)
#   ./install.sh --with-omz   # also install oh-my-zsh + external zsh plugins
#   ./install.sh --dry-run    # print what WOULD happen, change nothing
#   ./install.sh --help
#
# Re-running is safe: existing correct symlinks are left alone; real files are
# moved to ~/.dotfiles_backup/<timestamp>/ before being replaced.
# ============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0
WITH_OMZ=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --with-omz) WITH_OMZ=1 ;;
    --help|-h)
      sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg (try --help)"; exit 1 ;;
  esac
done

# Files symlinked straight into $HOME (repo name -> target uses same name)
HOME_FILES=(
  .shell_common.sh
  .zshrc .zprofile
  .bashrc .bash_profile .profile
  .vimrc .tmux.conf
  .gitconfig .gitignore_global
  .inputrc .editorconfig
  .condarc .Rprofile
)

say()  { printf '\033[0;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m[!]\033[0m %s\n' "$*"; }
run()  { if [ "$DRY_RUN" = 1 ]; then echo "    (dry-run) $*"; else eval "$*"; fi; }

# Symlink $1 (source) -> $2 (target), backing up any real file/dir at target.
link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "    ok: $dst already linked"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    run "mkdir -p '$BACKUP_DIR'"
    run "mv '$dst' '$BACKUP_DIR/'"
    warn "backed up existing $dst"
  fi
  run "mkdir -p '$(dirname "$dst")'"
  run "ln -s '$src' '$dst'"
  echo "    linked: $dst -> $src"
}

say "Dotfiles source: $DOTFILES_DIR"
[ "$DRY_RUN" = 1 ] && warn "DRY RUN — no changes will be made"

# --- 1. Home-directory dotfiles ---------------------------------------------
say "Linking home dotfiles..."
for f in "${HOME_FILES[@]}"; do
  [ -e "$DOTFILES_DIR/$f" ] && link "$DOTFILES_DIR/$f" "$HOME/$f"
done

# --- 2. starship config (lives under ~/.config) -----------------------------
if [ -e "$DOTFILES_DIR/starship.toml" ]; then
  say "Linking starship config..."
  link "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
fi

# --- 3. SSH config (COPY, don't symlink; never clobber an existing one) ------
say "Setting up SSH..."
run "mkdir -p '$HOME/.ssh/sockets'"
run "chmod 700 '$HOME/.ssh' '$HOME/.ssh/sockets'"
if [ ! -e "$HOME/.ssh/config" ]; then
  run "cp '$DOTFILES_DIR/ssh_config.example' '$HOME/.ssh/config'"
  run "chmod 600 '$HOME/.ssh/config'"
  warn "Created ~/.ssh/config from template — EDIT it with your real hosts."
else
  warn "~/.ssh/config already exists — left untouched. See ssh_config.example for ideas."
fi

# --- 4. Per-OS git credential helper into ~/.gitconfig.local (untracked) -----
if [ ! -e "$HOME/.gitconfig.local" ]; then
  say "Creating ~/.gitconfig.local (machine-local git overrides)..."
  if [ "$(uname -s)" = "Darwin" ]; then
    CRED="osxkeychain"
  else
    CRED="cache --timeout=3600"
  fi
  if [ "$DRY_RUN" = 1 ]; then
    echo "    (dry-run) would write ~/.gitconfig.local with credential helper '$CRED'"
  else
    cat > "$HOME/.gitconfig.local" <<LOCAL
# Machine-local git overrides (NOT tracked by the dotfiles repo).
# Override your identity here for work machines if needed.
[credential]
	helper = $CRED
LOCAL
    warn "Set git credential helper to '$CRED' in ~/.gitconfig.local"
  fi
fi

# --- 5. vim undo/swap/backup dirs (vimrc also creates these, belt+braces) ---
run "mkdir -p '$HOME/.vim/undo' '$HOME/.vim/swap' '$HOME/.vim/backup'"

# --- 6. Optional: oh-my-zsh + external zsh plugins (--with-omz) --------------
if [ "$WITH_OMZ" = 1 ]; then
  say "Installing oh-my-zsh + plugins..."
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    run "RUNZSH=no KEEP_ZSHRC=yes sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
  else
    echo "    ok: oh-my-zsh already installed"
  fi
  ZCUST="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  clone_plugin() {
    local repo="$1" name="$2"
    if [ ! -d "$ZCUST/plugins/$name" ]; then
      run "git clone --depth=1 'https://github.com/$repo' '$ZCUST/plugins/$name'"
    else
      echo "    ok: $name already present"
    fi
  }
  clone_plugin "zsh-users/zsh-autosuggestions" "zsh-autosuggestions"
  clone_plugin "zsh-users/zsh-syntax-highlighting" "zsh-syntax-highlighting"
else
  warn "Skipped oh-my-zsh (run with --with-omz to install it + plugins)."
fi

echo
say "Done."
[ -d "$BACKUP_DIR" ] && say "Backups of replaced files: $BACKUP_DIR"
say "Open a new shell, or run:  exec \$SHELL -l"
