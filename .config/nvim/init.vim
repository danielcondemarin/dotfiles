filetype plugin on

call plug#begin('~/.vim/plugged')

Plug 'hoob3rt/lualine.nvim'
Plug 'mileszs/ack.vim'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'tpope/vim-surround'
Plug 'martinda/Jenkinsfile-vim-syntax'
Plug 'tpope/vim-fugitive'
Plug 'joaohkfaria/vim-jest-snippets'
Plug 'machakann/vim-highlightedyank'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-dispatch'
Plug 'lambdalisue/fern.vim'
Plug 'lambdalisue/nerdfont.vim'
Plug 'lambdalisue/fern-renderer-nerdfont.vim'
Plug 'lambdalisue/glyph-palette.vim'
Plug 'antoinemadec/FixCursorHold.nvim'
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'
Plug 'tpope/vim-rhubarb'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }
Plug 'alvan/vim-closetag'
Plug 'cespare/vim-toml'
Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
Plug 'tpope/vim-commentary'
Plug 'honza/vim-snippets'
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'
Plug 'windwp/nvim-autopairs'
Plug 'folke/tokyonight.nvim'
Plug 'lewis6991/gitsigns.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'folke/lsp-trouble.nvim'
Plug 'mhinz/vim-startify'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
Plug 'rafamadriz/friendly-snippets'

call plug#end()

" Theme
"
let g:tokyonight_style = "storm"
syntax on
colorscheme tokyonight

if exists('+termguicolors')
  let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

" Set leader to space key
"
let mapleader = ' '

" Dashboard
"
let g:dashboard_default_executive ='fzf'

" Completion
"
let g:completion_confirm_key = "\<C-y>"
let g:completion_enable_snippet = 'vim-vsnip'
" let g:completion_enable_auto_hover = 0

" Autopairs
"
lua require'nvim-autopairs'.setup()

" Status line
"
lua << EOF
  require('lualine').setup {
    options = {
      theme = 'tokyonight'
    }
  }
EOF

" Treesitter
"
lua require'nvim-treesitter.configs'.setup { ensure_installed = "maintained", highlight = { enable = true } }

" Highlighted yanks
"
let g:highlightedyank_highlight_duration = 250

" Fern
"
let g:fern#renderer = "nerdfont"
