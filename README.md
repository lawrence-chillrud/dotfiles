# dotfiles

Personal development environment for an ML/DL researcher who works on a macOS
(Apple Silicon) laptop with iTerm + zsh, and constantly SSHes into Linux
servers and HPC clusters that mostly run bash. The goal: **one repo you clone
on any machine so every shell — local or remote — feels identical**, while
degrading gracefully on locked-down nodes where you can't install anything.

## Design principles

- **Local = zsh + oh-my-zsh, remote = bash, but they share a brain.** All the
  portable logic (aliases, functions, PATH, conda/fzf/zoxide/starship init)
  lives in `.shell_common.sh`, which both `.zshrc` and `.bashrc` source. Edit a
  shortcut once; it works in both shells on every machine.
- **Nothing assumes a tool is installed.** Every integration is guarded by
  `command -v`, so the same files run fine on a bare HPC login node with stock
  bash and on your fully-loaded laptop.
- **Symlinks, not copies.** `install.sh` symlinks files from the repo into
  `$HOME`, so editing a file in the repo updates the live config, and
  `git pull` propagates changes everywhere.
- **Machine-local escape hatches.** Anything host-specific (secrets, module
  loads, scratch paths, work git identity) goes in untracked `*.local` files
  that the dotfiles source automatically. The repo stays clean and shareable.

---

## Quick start

```bash
# 1. Clone (use your own repo URL once you've pushed this)
git clone https://github.com/lawrence-chillrud/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Preview what will change (optional but recommended the first time)
./install.sh --dry-run

# 3. Install. On your Mac (or any box where you want oh-my-zsh), add --with-omz.
./install.sh --with-omz      # laptop / workstation
./install.sh                 # bare HPC node (skip oh-my-zsh)

# 4. Reload
exec $SHELL -l
```

`install.sh` is idempotent: re-running it leaves correct symlinks alone and
moves any real files it would overwrite into `~/.dotfiles_backup/<timestamp>/`.

### What `install.sh` does

| Step | Action |
|------|--------|
| Home dotfiles | Symlinks `.zshrc`, `.bashrc`, `.vimrc`, etc. into `$HOME` (backing up existing ones). |
| starship | Symlinks `starship.toml` → `~/.config/starship.toml`. |
| SSH | Creates `~/.ssh/sockets` (for connection multiplexing) and **copies** `ssh_config.example` → `~/.ssh/config` only if you don't already have one. |
| git local | Writes `~/.gitconfig.local` with the right credential helper for the OS (`osxkeychain` on macOS, `cache` on Linux). |
| vim | Creates `~/.vim/{undo,swap,backup}`. |
| `--with-omz` | Installs oh-my-zsh and clones the `zsh-autosuggestions` + `zsh-syntax-highlighting` plugins. |

---

## File-by-file walkthrough

### `.shell_common.sh` — the shared core (sourced by both shells)
The most important file. Holds everything portable:

- **PATH** via an idempotent `path_prepend` helper (adds `~/.local/bin`,
  `~/bin`, `~/.cargo/bin`; never duplicates entries).
- **Modern-Unix swaps**, each only if installed: `ls`→`eza`/`exa`, `cat`→`bat`
  (handles Ubuntu's `batcat` rename), plus `rg`/`fd` helpers. Plain `ls`/`grep`
  get the right color flag for GNU vs BSD/macOS automatically.
- **General aliases**: `..`/`...`, `mkdir -p`, `reload`, `path`, safe
  `cp -i`/`mv -i`. Note `rm` is deliberately **not** made interactive (you
  delete big result dirs often); use the `trash` function for a safety net.
- **git, python/conda, GPU, tmux, opencode aliases.** Highlights: `act`/`deact`
  (mamba-aware activate), `mkenv myenv python=3.11`, `condaexport` (clean
  cross-platform `environment.yml`), `gpu`/`gpuw` (live GPU watch via gpustat or
  `watch nvidia-smi`), `oc`/`ocp` for opencode.
- **SLURM block** (only on clusters where `squeue` exists): `sq` (your jobs,
  readable), `sqa`, `si`, `interactive` (grabs a GPU node), `slog` (tail newest
  `slurm-*.out`).
- **Functions**: `mkcd`, `extract`, `trash`, `port`/`kport`, `serve`, `proj`
  (fzf-jump to a project dir).
- **Tool init for interactive shells**: finds and sources conda/mamba from the
  usual install roots (miniforge → mambaforge → miniconda → anaconda → /opt),
  then fzf, zoxide, and **starship last** (it owns the prompt).

> **Customize:** the `proj` function searches `~/projects ~/code ~/work` — point
> it at your actual roots. The conda search list and the `interactive` SLURM
> defaults (partition, gres, mem, time) are the things you'll most want to edit
> per cluster.

### `.zshrc` — interactive zsh (your Mac)
Thin layer over oh-my-zsh: theme `robbyrussell` (safe on any font; starship
overrides it when present), a curated `plugins=(...)` list, big shared history
with `SHARE_HISTORY`, `AUTO_CD`/`AUTO_PUSHD`, case-insensitive menu completion,
and history-substring-search bound to the arrow keys. Sources `.shell_common.sh`
then `~/.zshrc.local`.

> **Customize:** swap `ZSH_THEME` if you don't use starship; add/remove plugins.

### `.zprofile` — zsh login shells
Runs once at login. Its main job is **Homebrew on Apple Silicon**
(`/opt/homebrew`), with fallbacks for Intel macs and Linuxbrew. Sources
`~/.zprofile.local`.

### `.bashrc` — interactive bash (your servers/HPC)
The bash mirror of `.zshrc`. Returns early for non-interactive shells (after
ensuring `~/.local/bin` is on PATH so scripts/`scp` still work). Sets large
de-duplicated timestamped history synced across shells, useful `shopt`s
(`autocd`, `globstar`, `cdspell`), and bash-completion. Sources
`.shell_common.sh`. Includes a **fallback prompt** (used when starship isn't
installed) showing conda env, `user@host` over SSH, cwd, git branch, and a red
prompt symbol on non-zero exit. Sources `~/.bashrc.local`.

### `.bash_profile` / `.profile`
`.bash_profile` (read by **login** bash) sources `.profile` then `.bashrc`, so
`ssh server` gives you the exact same environment as a local pane. `.profile` is
kept strictly POSIX for `/bin/sh`/dash contexts and only sets PATH essentials.

### `.vimrc` — your remote editor
Fully functional with **zero plugins** (critical on HPC). Hybrid line numbers,
true-color when supported, 4-space soft tabs (2 for yaml/json/R/web, real tabs
for Makefiles), smart search, system-clipboard yank, persistent undo with
auto-created dirs, spacebar leader, vim-style window navigation. An **optional**
vim-plug block at the bottom activates only if you've installed vim-plug, so it
never errors on a bare node.

> **Customize:** to enable plugins, install vim-plug (one `curl` command shown
> in the file) and run `:PlugInstall`. Add/remove plugins in that block.

### `.tmux.conf` — survive SSH drops
Your training jobs live inside tmux so a dropped connection doesn't kill them.
Keeps the default `C-b` prefix (won't fight readline), enables mouse, 100k-line
scrollback, true-color passthrough, intuitive `|`/`-` splits that inherit the
cwd, vim copy-mode (with `pbcopy` on Mac), and a compact status bar that shows
the **hostname** (so you always know which cluster you're on). `prefix + r`
reloads. Optional TPM block (guarded) adds session persistence.

### `.gitconfig` + `.gitignore_global`
Sensible modern git: `main` default branch, `pull.rebase`, `push.autoSetupRemote`,
`fetch.prune`, `zdiff3` conflict style, histogram diff, `rerere`, autocorrect,
and a batch of aliases (`st`, `lg`, `wip`, `undo`, `review`, …). The global
ignore covers OS cruft, Python/Jupyter, conda, **R+renv** (commits `renv.lock`,
ignores the heavy `renv/library/`), and common **ML artifacts** (`*.ckpt`,
`*.safetensors`, `wandb/`, `mlruns/`, `checkpoints/`, …) plus secrets.

> **Customize (do this first):** edit the `[user]` name/email. Per-machine or
> work identities, signing keys, and the credential helper go in
> `~/.gitconfig.local` (created for you by the installer, untracked).
> `delta` and `git-lfs` blocks are present but commented — enable after
> installing those tools. The `.vscode/` ignore is on by default; comment it
> out in repos where your team commits shared VS Code settings.

### `.inputrc`
Upgrades GNU readline (bash, python REPL, psql, …) on every machine:
case-insensitive completion, show-all-on-ambiguous, colored completions, and
prefix history search on the arrow keys. zsh ignores this (it has its own line
editor) — covered by `.zshrc` instead.

### `.editorconfig`
Cross-editor formatting consistency (VS Code honors it natively): UTF-8, LF,
final newline, trim trailing whitespace, and per-language indent widths (Python
4 / line length 88 for black+ruff, 2 for yaml/json/R/web, tabs for Makefiles).

### `.condarc` — mamba/conda
`conda-forge` first with **strict channel priority** (the single most important
setting for stable solves), `auto_activate_base: false`, libmamba solver,
pip-interop on. Includes a commented **HPC tip** to relocate `envs_dirs`/
`pkgs_dirs` onto scratch storage so you don't blow your home quota.

> **Customize:** on each cluster, uncomment `envs_dirs`/`pkgs_dirs` and point
> them at `/scratch/$USER/...`.

### `.Rprofile` — R + renv
User-level R defaults that coexist with renv's per-project `.Rprofile`: fast
CRAN mirror, parallel compilation (`Ncpus = detectCores()`), sane print/scipen
options, a renv-detection message, and optional `rlang` tracebacks. Includes a
commented **HPC tip** to pull prebuilt Linux binaries from Posit Public Package
Manager (P3M) instead of compiling from source.

> **Customize:** uncomment the P3M block and set your distro codename
> (`lsb_release -cs`) on Linux clusters for vastly faster R installs.

### `starship.toml` → `~/.config/starship.toml`
Cross-shell prompt so zsh and bash look identical everywhere. Tuned for SSH:
shows hostname **only when remote**, conda/python env, compact git status, and
command duration for slow commands (≥2s). `command_timeout` keeps it snappy.

> **Customize:** edit the `format` line to reorder modules. The `[conda]` module
> is disabled on purpose (conda's own `(env)` prefix is used so the label is
> identical in both shells); flip `disabled = false` if you prefer starship's.

### `ssh_config.example` → `~/.ssh/config`
**Template, not a symlink** — your real SSH config has host-specific info that
usually shouldn't live in a public repo, so the installer copies it only if you
have none. Provides connection keep-alives, **multiplexing** (big speedup for
VS Code Remote-SSH and rapid `ssh`/`rsync`), agent forwarding, and worked
examples for a plain server, an HPC cluster reached via a `ProxyJump` bastion,
and a wildcard for internal compute nodes.

> **Customize:** replace the example hosts with yours. If a cluster's MFA fights
> with multiplexing, set `ControlMaster no` for that host.

---

## Working with VS Code Remote-SSH

These dotfiles make remote VS Code smoother in two ways:

1. **SSH multiplexing** (`ControlMaster`/`ControlPath` in `ssh_config.example`)
   means the extra channels VS Code opens reuse your first authenticated
   connection — faster reconnects, fewer MFA prompts.
2. Your remote integrated terminal inherits the **same** aliases/functions/
   prompt as local, because the server is running these dotfiles too.

VS Code's own settings (`settings.json`, keybindings, extensions) live in
Application Support / the server's `~/.vscode-server` and are best synced with
the built-in **Settings Sync** feature rather than this repo. The
`.editorconfig` here still governs formatting in every VS Code window.

---

## Setting up a brand-new machine (cheat sheet)

**On your Mac:**
```bash
git clone https://github.com/lawrence-chillrud/dotfiles.git ~/dotfiles
~/dotfiles/install.sh --with-omz
# then install the optional tools (see below) via Homebrew
```

**On a new server / HPC login node:**
```bash
git clone https://github.com/lawrence-chillrud/dotfiles.git ~/dotfiles
~/dotfiles/install.sh        # no --with-omz if you can't/won't install oh-my-zsh
exec $SHELL -l
# create machine-local tweaks if needed:
#   echo 'module load cuda/12.4' >> ~/.bashrc.local
#   (edit ~/.condarc to point envs_dirs at scratch)
```

Everything works immediately with stock tools; installing the optional tools
below just unlocks the nicer aliases/prompt.

### Troubleshooting: `Error unknown MAMBA_EXE` on startup

If you see this error when opening a terminal on macOS, it means mamba's initialization script ran but couldn't find the mamba executable. This usually happens if:

1. **Mamba was installed via Homebrew but isn't on PATH yet** — The `.zprofile` sources Homebrew's setup, then `.zshrc` sources `.shell_common.sh` which tries to initialize mamba. The timing can be tight.
   
   **Fix:** Open a new terminal (forces a fresh login shell), or run `exec $SHELL -l`.

2. **Mamba install is incomplete or partially corrupted** — This is rare but the dotfiles guard against it by suppressing stderr and checking that the mamba binary actually exists before sourcing `mamba.sh`.
   
   **Fix:** Reinstall mamba: `brew reinstall mambaforge` or `brew install miniforge`.

3. **You have multiple conda roots** and the wrong one is being picked up.
   
   **Fix:** Check which mamba is on your PATH: `which mamba`. If it's not from your intended install root, edit `.shell_common.sh` to reorder the conda root search list to check your preferred one first.

If the error persists, you can safely **disable mamba function initialization** by editing `.shell_common.sh` and removing the `mamba.sh` sourcing block entirely — `conda activate` will still work (just slower).

---

## Optional tools (unlock the full experience)

None are required — the dotfiles detect and use them if present.

### Tools overview (in plain English)

If you're new to these tools, here's what each one does:

| Tool | What it does | Why it's handy | Notes |
|------|--------------|----------------|-------|
| **starship** | Custom shell prompt that shows your current directory, git branch, and which conda environment you're in — with colors and symbols. | Instantly see where you are and what's uncommitted. Works identically in zsh and bash everywhere. | If you don't install it, `.bashrc` falls back to a plain prompt; `.zshrc` uses oh-my-zsh's theme. |
| **fzf** | Fuzzy finder: type part of a filename or command and it shows matching results you can select with arrow keys. Integrates into `Ctrl-R` (history search), `Ctrl-T` (file search), and `Alt-C` (directory jump). | Dramatically faster than typing full paths or re-running commands. Goes from searching through 1,000 lines of history to finding what you want in 2 keypresses. | Requires `fd` to be really fast (without it, `find` is the fallback). |
| **zoxide** | Smarter `cd`: type `z projname` to jump to `/path/to/projects/projname` without the full path. Learns which directories you visit most. | Beats `proj` function for day-to-day jumping; you type less. | Like autojump or z, but faster (Rust). The `proj` function is an fzf-powered alternative if you prefer fuzzy picking. |
| **eza** / **exa** | Prettier replacement for `ls` that shows colors, file type icons, and git status in the listing. | Instantly spot directories vs files vs symlinks; see which files are git-tracked/ignored at a glance. | `eza` is the maintained fork of `exa`; both work. Gracefully falls back to colored `ls` if neither is installed. |
| **bat** | Like `cat` but with syntax highlighting and line numbers, using the same logic as VS Code. | Read through logs/code snippets without squinting; highlights jump out. | Ubuntu calls it `batcat`; these dotfiles handle both names. |
| **ripgrep** (`rg`) | Much faster `grep` for searching file contents. Respects `.gitignore` (doesn't search build dirs / vendored code) and prints colored output. | Searching 10,000 files is instant. Perfect for "where does this function live?" queries. | Pairs beautifully with fzf: search with rg, pick the result, open in your editor. |
| **fd** | Much faster and friendlier `find` for searching for files by name. Default shows only regular files (not broken symlinks). Respects `.gitignore`. | `find`'s syntax is notoriously cryptic. `fd pattern` just works. Also way faster. | fzf uses `fd` under the hood if it's installed; without it falls back to `find`. |
| **git-delta** | Prettier diffs: shows side-by-side comparisons, syntax-highlights code, and highlights exactly which characters changed (not just whole lines). | Reading a 50-line diff becomes painless. Perfect when reviewing pull requests. | Optional: commented out in `.gitconfig`. Install if you want fancy diffs. |
| **gpustat** | Pretty live view of GPU usage (memory, utilization, temperature) in a one-liner. | Beats staring at dense `nvidia-smi` output. Great for checking if training is actually using the GPU. | Falls back to `watch nvidia-smi` if not installed; both are aliased as `gpuw`. |
| **tmux** | Terminal multiplexer: run multiple shells inside one connection. Survives SSH drops. | Your training job keeps running if the connection dies. Organize a cluster session into panes for monitoring, logs, and code editing. | Your `.tmux.conf` is pre-configured; `prefix + |` makes vertical splits. |
| **vim-plug** | Plugin manager for vim: one-liner setup to add quality-of-life plugins (git integration, fuzzy finder, comments, surround, syntax packs). | `.vimrc` works out of the box, but vim-plug unlocks things like `:Files` fuzzy search and `:Gblame` git history. | Install once per machine: `curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim` then `:PlugInstall`. |

**The golden trio for daily use:** fzf (search), zoxide (navigation), and starship (context). Install those three and your shell becomes 10x faster.

**macOS (Homebrew):**
```bash
brew install starship fzf zoxide eza bat ripgrep fd git-delta tmux gpustat
$(brew --prefix)/opt/fzf/install   # fzf key-bindings (or rely on `fzf --zsh`)
```

**Linux / HPC (no sudo — installs into your home):**
```bash
# starship
curl -sS https://starship.rs/install.sh | sh -s -- -b ~/.local/bin
# fzf
git clone --depth 1 https://github.com/junegunn/fzf ~/.fzf && ~/.fzf/install
# zoxide
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
# Many clusters already provide eza/bat/ripgrep/fd via `module` or conda:
#   mamba install -n base -c conda-forge ripgrep fd-find bat eza
```

| Tool | Replaces / adds | Used by |
|------|-----------------|---------|
| starship | prompt | both shells (`.shell_common.sh`) |
| fzf | fuzzy find (Ctrl-R history, Ctrl-T files) | shells, `proj`, vim |
| zoxide | smart `cd` → `z` | shells |
| eza / bat | `ls` / `cat` | aliases |
| ripgrep / fd | `grep` / `find` | aliases, fzf |
| git-delta | git diff pager | `.gitconfig` (commented) |
| gpustat | nicer `nvidia-smi` watch | `gpuw` |

---

## Updating

```bash
cd ~/dotfiles && git pull
```
Because the files are symlinked, pulling updates every machine's live config —
no re-install needed unless you've **added a new file** to the repo (then re-run
`./install.sh`).

## Uninstalling

If you want to revert to your old config or remove these dotfiles entirely:

```bash
# Option 1: restore the most recent backup (symlinks are deleted automatically)
BACKUP_DIR=$(ls -td ~/.dotfiles_backup/*/ 2>/dev/null | head -1)
if [ -n "$BACKUP_DIR" ]; then
  echo "Restoring from: $BACKUP_DIR"
  cp -v "$BACKUP_DIR"* ~/    # copy old files back
  rm -f ~/.shell_common.sh ~/.zshrc ~/.zprofile ~/.bashrc ~/.bash_profile ~/.profile \
        ~/.vimrc ~/.tmux.conf ~/.gitconfig ~/.gitignore_global ~/.inputrc \
        ~/.editorconfig ~/.condarc ~/.Rprofile ~/.config/starship.toml
  echo "Restored."
else
  echo "No backup directory found."
fi

# Option 2: just remove the symlinks (leaving dotfiles/ cloned for reference)
rm -f ~/.shell_common.sh ~/.zshrc ~/.zprofile ~/.bashrc ~/.bash_profile ~/.profile \
      ~/.vimrc ~/.tmux.conf ~/.gitconfig ~/.gitignore_global ~/.inputrc \
      ~/.editorconfig ~/.condarc ~/.Rprofile ~/.config/starship.toml
# Also undo the SSH multiplexing setup (optional, safe to leave):
# rm -rf ~/.ssh/sockets

# Option 3: nuke everything (repo + symlinks + backups)
rm -rf ~/dotfiles ~/.dotfiles_backup ~/.shell_common.sh ~/.zshrc ~/.zprofile \
       ~/.bashrc ~/.bash_profile ~/.profile ~/.vimrc ~/.tmux.conf ~/.gitconfig \
       ~/.gitignore_global ~/.inputrc ~/.editorconfig ~/.condarc ~/.Rprofile \
       ~/.config/starship.toml ~/.ssh/sockets
```

The safest approach: restore from the backup, then decide if you want to keep the
`~/dotfiles` repo for reference.

---

## Repo layout
```
dotfiles/
├── install.sh            # idempotent symlink bootstrapper (--with-omz, --dry-run)
├── README.md
├── .shell_common.sh      # shared core: aliases/functions/PATH/tool-init
├── .zshrc  .zprofile     # local zsh (oh-my-zsh, Homebrew)
├── .bashrc .bash_profile .profile   # remote bash login chain
├── .vimrc                # plugin-free base + optional vim-plug block
├── .tmux.conf            # SSH-resilient terminal multiplexer
├── .gitconfig .gitignore_global
├── .inputrc .editorconfig
├── .condarc              # mamba/conda
├── .Rprofile             # R + renv
├── starship.toml         # → ~/.config/starship.toml
└── ssh_config.example    # → copied to ~/.ssh/config (edit it)
```

**Untracked per-machine files** the dotfiles will source if present:
`~/.zshrc.local`, `~/.bashrc.local`, `~/.zprofile.local`, `~/.gitconfig.local`.
