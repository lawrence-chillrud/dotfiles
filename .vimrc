" ============================================================================
" ~/.vimrc  —  sane, dependency-free defaults that also work great on HPC
" ----------------------------------------------------------------------------
" This config is fully functional with ZERO plugins (important on locked-down
" login nodes). An OPTIONAL plugin section at the bottom only activates if
" vim-plug is already installed, so it never errors on a bare machine.
" ============================================================================

set nocompatible              " behave like vim, not vi
filetype plugin indent on     " filetype detection + per-type indent rules
syntax enable

" --- Display ----------------------------------------------------------------
set number relativenumber     " hybrid line numbers (absolute current, relative rest)
set ruler                     " row/col in the corner
set showcmd                   " show partial commands as you type
set showmatch                 " briefly jump to matching bracket
set cursorline                " highlight the current line
set scrolloff=5               " keep 5 lines of context above/below cursor
set sidescrolloff=8
set wrap linebreak            " soft-wrap at word boundaries, don't split words
set laststatus=2              " always show the status line
set wildmenu                  " visual command-line completion menu
set wildmode=longest:full,full
set lazyredraw                " smoother on slow/SSH connections
set ttyfast

" --- True color (only if the terminal supports it; iTerm + tmux do) ---------
if has('termguicolors') && ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit')
  set termguicolors
endif
silent! colorscheme habamax   " ships with vim 8.2+; falls back silently if absent
set background=dark

" --- Indentation (default 4-space soft tabs; Python-friendly) ---------------
set expandtab                 " spaces, not tabs
set shiftwidth=4
set tabstop=4
set softtabstop=4
set autoindent
set smartindent
set shiftround                " round indent to multiples of shiftwidth

" --- Search -----------------------------------------------------------------
set incsearch                 " jump to matches as you type
set hlsearch                  " highlight all matches
set ignorecase                " case-insensitive...
set smartcase                 " ...unless the pattern has an uppercase letter

" --- Editing behavior -------------------------------------------------------
set backspace=indent,eol,start
set hidden                    " switch buffers without saving
set autoread                  " reload files changed outside vim
set mouse=a                   " mouse support (resize splits, scroll)
set encoding=utf-8
set clipboard=unnamed         " yank to system clipboard where supported
if has('unnamedplus') | set clipboard^=unnamedplus | endif
set splitbelow splitright     " open new splits where you'd expect
set updatetime=300
set timeoutlen=500

" --- Persistent undo + keep the working tree clean of swap/backup files -----
set undofile
set undodir=$HOME/.vim/undo//
set directory=$HOME/.vim/swap//
set backupdir=$HOME/.vim/backup//
" Auto-create those dirs so undo/swap actually work on a fresh machine
for s:d in [&undodir, &directory, &backupdir]
  if !isdirectory(expand(s:d)) | call mkdir(expand(s:d), 'p', 0700) | endif
endfor

" --- Leader + handy mappings ------------------------------------------------
let mapleader = " "                       " spacebar is the leader key
nnoremap <leader><space> :nohlsearch<CR>  " clear search highlight
nnoremap <leader>w :w<CR>                 " quick save
nnoremap <leader>q :q<CR>
" Move between windows with Ctrl-h/j/k/l instead of Ctrl-w then a key
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
" Keep visual selection while indenting
vnoremap < <gv
vnoremap > >gv
" Yank to end of line like C and D
nnoremap Y y$
" Re-open a file at the last cursor position
autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif

" --- Filetype-specific indentation ------------------------------------------
augroup filetype_indent
  autocmd!
  autocmd FileType yaml,yml,json,html,css,javascript,typescript,r setlocal shiftwidth=2 tabstop=2 softtabstop=2
  autocmd FileType make setlocal noexpandtab        " Makefiles REQUIRE real tabs
  autocmd FileType markdown,text setlocal spell spelllang=en_us
  autocmd FileType python setlocal colorcolumn=89   " visual PEP8-ish guide
augroup END

" ============================================================================
" OPTIONAL PLUGINS — only load if vim-plug is already installed.
" To enable on a machine you control:
"   curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
"     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"   then open vim and run  :PlugInstall
" On HPC nodes without internet this block is simply skipped — no errors.
" ============================================================================
if filereadable(expand('~/.vim/autoload/plug.vim'))
  call plug#begin('~/.vim/plugged')
    Plug 'tpope/vim-sensible'        " baseline sensible defaults
    Plug 'tpope/vim-fugitive'        " :Git / :Gblame inside vim
    Plug 'tpope/vim-commentary'      " gcc / gc to (un)comment
    Plug 'tpope/vim-surround'        " cs"' etc. to change surroundings
    Plug 'airblade/vim-gitgutter'    " git diff signs in the gutter
    Plug 'sheerun/vim-polyglot'      " language packs (incl. python, R, julia)
    Plug 'junegunn/fzf.vim'          " :Files :Rg fuzzy finding (needs fzf binary)
  call plug#end()
  " gitgutter is noisy over SSH; throttle it
  let g:gitgutter_max_signs = 500
endif
