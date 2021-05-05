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

call plug#end()

" REMAP LEADER TO SPACE KEY 
"
let mapleader = ' '

" THEME
"
let g:tokyonight_style = "storm"
syntax on
colorscheme tokyonight

" Dashboard
"
let g:dashboard_default_executive ='fzf'

" checks if your terminal has 24-bit color support
if (has("termguicolors"))
    set termguicolors
endif

" Completion
"
let g:completion_confirm_key = "\<C-y>"
let g:completion_enable_auto_hover = 0
imap <expr> <cr>  pumvisible() ? complete_info()["selected"] != "-1" ?
                 \ "\<Plug>(completion_confirm_completion)"  : "\<c-e>\<CR>" :  "\<CR>"
" Autopairs
"
lua << EOF
  require'nvim-autopairs'.setup()
EOF
 
lua << EOF
  -- status line
  require('lualine').setup {
    options = {
      theme = 'tokyonight'
    }
  }
EOF

" Treesitter
"
lua require'nvim-treesitter.configs'.setup { ensure_installed = "maintained", highlight = { enable = true } }

" HIGHLIGHTED YANK
"
let g:highlightedyank_highlight_duration = 250

" FERN
"
let g:fern#renderer = "nerdfont"
