set nocompatible
set exrc 
set nohlsearch
set noerrorbells
set relativenumber
set backspace=indent,eol,start
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set nowrap
set smartindent
set autoindent
set incsearch
set scrolloff=8
set encoding=UTF-8
set guifont=VictorMono\ Nerd\ Font:h17
set cursorline
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
set foldlevelstart=99
set listchars=tab:→\ ,eol:↲,nbsp:␣,trail:•,extends:⟩,precedes:⟨
set showbreak=↪\ 
set updatetime=50
" set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect
" avoid showing message extra message when using completion
set shortmess+=c
" display all matching files when we tab complete
set wildmenu
" global ignore when finding files
set wildignore+=**/node_modules/**,**/.git/**

