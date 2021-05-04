" BASIC SETTINGS
"
set nocompatible
set backspace=indent,eol,start
set tabstop=2
set softtabstop=2
set shiftwidth=2
set autoindent
set smartindent
set expandtab
set relativenumber
set hlsearch
set encoding=UTF-8
set guifont=VictorMono\ Nerd\ Font:h17
set cursorline
set foldmethod=syntax 
set foldlevelstart=99
set nowrap
filetype plugin on
" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=100
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
set listchars=tab:→\ ,eol:↲,nbsp:␣,trail:•,extends:⟩,precedes:⟨
set showbreak=↪\ 
" set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect
" avoid showing message extra message when using completion
set shortmess+=c

" REMAP LEADER TO SPACE KEY 
"
let mapleader = ' '

" DISPLAY ALL MATCHING FILES WHEN WE TAB COMPLETE
"
set wildmenu

" GLOBAL IGNORE WHEN FINDING FILES
"
set wildignore+=**/node_modules/**,**/.git/**

" TAG JUMPING
" 
" - Use ^] to jump to tag
" - Use g^] for ambiguous tags
" - Use ^t to jump back up the tag stack
command! MakeTags !ctags -R --exclude=.git --exclude=node_modules .

" MAPPINGS
"
" search and replace
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>
nnoremap <Leader>F :Ack! -F "" <Left><Left>
nnoremap <Leader>R 
  \ :cfdo %s///gc \| update
  \<Left><Left><Left><Left><Left><Left><Left><Left><Left><Left><Left><Left><Left>
nnoremap <silent> <c-p> :Files<CR>
nnoremap <silent> <c-s> :Buffers<CR>

" quickfix list
noremap [q :cprev <CR>
noremap ]q :cnext <CR>

" disable arrow keys
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>

" clipboard copy / paste
noremap <Leader>y "+y
noremap <Leader>p "+p

" visually select entire buffer
nnoremap vy ggVG

" save buffer
nnoremap zz :update<cr>

" toggle search highlight
nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>

" vim fugitive
nnoremap <leader>gh :diffget //2<CR>
nnoremap <leader>gl :diffget //3<CR>
nnoremap <leader>gs :20GStatus<CR>
command Gpp :Gpull | Gpush<CR>

" tabs
map <Leader>t :tabnew<CR>

" lsp
" diagnostics
nnoremap ]g <cmd>lua vim.lsp.diagnostic.goto_next { wrap = false }<CR>
nnoremap [g <cmd>lua vim.lsp.diagnostic.goto_prev { wrap = false }<CR>

" fern
map <leader>n :Fern . -drawer -toggle -reveal=% -width=40<cr>
function! s:init_fern() abort
  " Use 'select' instead of 'edit' for default 'open' action
  nmap <buffer> <Plug>(fern-action-open) <Plug>(fern-action-open:select)
  nmap <buffer> M <Plug>(fern-action-move) 
  nmap <buffer> F <Plug>(fern-action-new-file) 
  nmap <buffer> D <Plug>(fern-action-new-dir) 
  nmap <buffer> dd <Plug>(fern-action-trash) 
endfunction

augroup fern-custom
  autocmd! *
  autocmd FileType fern call s:init_fern()
augroup END
augroup glyph-palette
  autocmd! *
  autocmd FileType fern call glyph_palette#apply()
augroup END
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  endif
endfunction

" Dockerfile
augroup dockerfile
  au!
  autocmd BufNewFile,BufRead Dockerfile.* set syntax=dockerfile
augroup END

" PLUGINS
"
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

call plug#end()

" THEME
"
syntax on
colorscheme tokyonight

hi Normal guibg=NONE ctermbg=NONE
hi LineNr guibg=NONE ctermbg=NONE
hi SignColumn guibg=NONE ctermbg=NONE
hi EndOfBuffer guibg=NONE ctermbg=NONE

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

  -- git signs
  require('gitsigns').setup {
    signs = {
      add          = {hl = 'GitSignsAdd'   , text = '│', numhl='GitSignsAddNr'   , linehl='GitSignsAddLn'},
      change       = {hl = 'GitSignsChange', text = '│', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
      delete       = {hl = 'GitSignsDelete', text = '_', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
      topdelete    = {hl = 'GitSignsDelete', text = '‾', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
      changedelete = {hl = 'GitSignsChange', text = '~', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
    },
    numhl = false,
    linehl = false,
    keymaps = {
      -- Default keymap options
      noremap = true,
      buffer = true,

      ['n ]c'] = { expr = true, "&diff ? ']c' : '<cmd>lua require\"gitsigns\".next_hunk()<CR>'"},
      ['n [c'] = { expr = true, "&diff ? '[c' : '<cmd>lua require\"gitsigns\".prev_hunk()<CR>'"},

      ['n <leader>hs'] = '<cmd>lua require"gitsigns".stage_hunk()<CR>',
      ['n <leader>hu'] = '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>',
      ['n <leader>gu'] = '<cmd>lua require"gitsigns".reset_hunk()<CR>',
      ['n <leader>gU'] = '<cmd>lua require"gitsigns".reset_buffer()<CR>',
      ['n <leader>gp'] = '<cmd>lua require"gitsigns".preview_hunk()<CR>',
      ['n <leader>hb'] = '<cmd>lua require"gitsigns".blame_line()<CR>',

      -- Text objects
      ['o ih'] = ':<C-U>lua require"gitsigns".select_hunk()<CR>',
      ['x ih'] = ':<C-U>lua require"gitsigns".select_hunk()<CR>'
    },
    watch_index = {
      interval = 1000
    },
    current_line_blame = false,
    sign_priority = 6,
    update_debounce = 100,
    status_formatter = nil, -- Use default
    use_decoration_api = true,
    use_internal_diff = true,  -- If luajit is present
  }
EOF

" LSP
"

lua << EOF
local nvim_lsp = require('lspconfig')
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[g', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']g', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

  -- Set some keybinds conditional on server capabilities
  if client.resolved_capabilities.document_formatting then
    buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  end
  if client.resolved_capabilities.document_range_formatting then
    buf_set_keymap("v", "<space>f", "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
  end

  -- Set autocommands conditional on server_capabilities
  if client.resolved_capabilities.document_highlight then
     vim.api.nvim_exec([[
       hi LspReferenceText guifg=NONE guibg=#444444 guisp=NONE gui=bold,italic cterm=bold,italic
       hi LspReferenceRead guifg=NONE guibg=#444444 guisp=NONE gui=bold,italic cterm=bold,italic
       hi LspReferenceWrite guifg=NONE guibg=#444444 guisp=NONE gui=bold,italic cterm=bold,italic
       augroup lsp_document_highlight
         autocmd! * <buffer>
         autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
         autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
       augroup END
     ]], false)
  end

  require'completion'.on_attach(client, bufnr)
end

-- Use a loop to conveniently both setup defined servers 
-- and map buffer local keybindings when the language server attaches
local servers = { "gopls", "rust_analyzer", "tsserver", "jsonls" }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup { on_attach = on_attach }
end
EOF

" Treesitter
"
lua require'nvim-treesitter.configs'.setup { ensure_installed = "maintained", highlight = { enable = true } }

" Fugitive
" temporary until lerna (or maybe lint-staged fixes this issue, see https://github.com/tpope/vim-fugitive/issues/1446)
let g:fugitive_pty = 0

" SEARCHING TEXT (AG)
"
"
" Use ripgrep for searching ⚡️
" Options include:
" --vimgrep -> Needed to parse the rg response properly for ack.vim
" --type-not sql -> Avoid huge sql file dumps as it slows down the search
" --smart-case -> Search case insensitive if all lowercase pattern, Search case sensitively otherwise
let g:ackprg = 'rg --vimgrep --type-not sql --smart-case'

" Auto close the Quickfix list after pressing '<enter>' on a list item
let g:ack_autoclose = 1

" Any empty ack search will search for the work the cursor is on
let g:ack_use_cword_for_empty_search = 1

" Don't jump to first match
cnoreabbrev Ack Ack!

" Maps <leader>/ so we're ready to type the search keyword
nnoremap <Leader>/ :Ack!<Space>
" }}}

" FUZZY FILE FINDER
"
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.9 } }
let $FZF_DEFAULT_OPTS="--ansi --preview-window 'right:60%' --layout reverse --margin=1,4 --preview 'bat --color=always --style=header,grid --line-range :300 {}'"
let $FZF_DEFAULT_COMMAND = 'rg --files --ignore-case --hidden -g "!{.git,node_modules}/*"'
command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'options': ['--layout=reverse', '--info=inline']}), <bang>0)

let g:fzf_buffers_jump = 1

" HIGHLIGHTED YANK
"
let g:highlightedyank_highlight_duration = 250

" Git coauthors autocomplete
"
command! -nargs=+ Gca :r!git log -n400 --pretty=format:"\%an <\%ae>" | grep -i '<args>' | head -1 | xargs echo "Co-authored-by:"

" VIM CLOSETAG
" filenames like *.xml, *.html, *.xhtml, ...
" These are the file extensions where this plugin is enabled.
"
let g:closetag_filenames = '*.html,*.xhtml,*.phtml,*.tsx,*.jsx'

" filenames like *.xml, *.xhtml, ...
" This will make the list of non-closing tags self-closing in the specified files.
"
let g:closetag_xhtml_filenames = '*.xhtml,*.jsx,*.tsx'

" filetypes like xml, html, xhtml, ...
" These are the file types where this plugin is enabled.
"
let g:closetag_filetypes = 'html,xhtml,phtml,javascriptreact,typescriptreact'

" filetypes like xml, xhtml, ...
" This will make the list of non-closing tags self-closing in the specified files.
"
let g:closetag_xhtml_filetypes = 'xhtml,javascriptreact,typescriptreact'

" integer value [0|1]
" This will make the list of non-closing tags case-sensitive (e.g. `<Link>` will be closed while `<link>` won't.)
"
let g:closetag_emptyTags_caseSensitive = 1

" dict
" Disables auto-close if not in a "valid" region (based on filetype)
"
let g:closetag_regions = {
    \ 'typescript.tsx': 'jsxRegion,tsxRegion',
    \ 'javascript.jsx': 'jsxRegion',
    \ }

" Shortcut for closing tags, default is '>'
"
let g:closetag_shortcut = '>'

" Add > at current position without closing the current tag, default is ''
"
"let g:closetag_close_shortcut = '<leader>>'

" FERN
"
let g:fern#renderer = "nerdfont"
