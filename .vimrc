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
set guifont=FuraCode\ Nerd\ Font:h17
set cursorline
set foldmethod=syntax 
set foldlevelstart=99
set nowrap
filetype plugin on
syntax on
" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=100
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
set listchars=tab:→\ ,eol:↲,nbsp:␣,trail:•,extends:⟩,precedes:⟨
set showbreak=↪\ 

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

" signify
nnoremap <leader>gp :SignifyHunkDiff<cr>
nnoremap <leader>gu :SignifyHunkUndo<cr>

" coc
nmap <leader>rn <Plug>(coc-rename)
nmap <leader>qf <Plug>(coc-fix-current)
autocmd CursorHold * silent call CocActionAsync('highlight')
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
inoremap <silent><expr> <c-space> coc#refresh()
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gr <Plug>(coc-references)
vmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)
nnoremap <silent> K :call <SID>show_documentation()<CR>

" go
autocmd FileType go nmap <leader>gtj :CocCommand go.tags.add json<cr>
autocmd FileType go nmap <leader>gty :CocCommand go.tags.add yaml<cr>
autocmd FileType go nmap <leader>gtx :CocCommand go.tags.clear<cr>
autocmd BufWritePre *.go :silent call CocAction('runCommand', 'editor.action.organizeImport')
" disable lsp vim-go and other feats
let g:go_fmt_fail_silently=1
let g:go_gopls_enabled=0
let g:go_diagnostics_enabled=0
let g:go_def_mapping_enabled=0
let g:go_def_mapping_enabled=0
let g:go_doc_keywordprg_enabled=0

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
  else
    call CocAction('doHover')
  endif
endfunction

" Dockerfile
augroup dockerfile
  au!
  autocmd BufNewFile,BufRead Dockerfile.* set syntax=dockerfile
augroup END

" coc-snippets
"
" Use <C-l> for trigger snippet expand.
imap <C-l> <Plug>(coc-snippets-expand)
 
" Use <C-j> for select text for visual placeholder of snippet.
vmap <C-j> <Plug>(coc-snippets-select)

" Use <C-j> for jump to next placeholder, it's default of coc.nvim
let g:coc_snippet_next = '<c-j>'

" Use <C-k> for jump to previous placeholder, it's default of coc.nvim
let g:coc_snippet_prev = '<c-k>'

" Use <C-j> for both expand and jump (make expand higher priority.)
imap <C-j> <Plug>(coc-snippets-expand-jump)

" Use <leader>x for convert visual selected code to snippet
xmap <leader>x  <Plug>(coc-convert-snippet)

" PLUGINS
"
call plug#begin('~/.vim/plugged')

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'mileszs/ack.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'ryanoasis/vim-devicons'
Plug 'tpope/vim-surround'
Plug 'martinda/Jenkinsfile-vim-syntax'
Plug 'tpope/vim-fugitive'
Plug 'joaohkfaria/vim-jest-snippets'
Plug 'machakann/vim-highlightedyank'
Plug 'mhinz/vim-signify'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'joshdick/onedark.vim'
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
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'fatih/vim-go'
Plug 'tpope/vim-commentary'
Plug 'honza/vim-snippets'

call plug#end()

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

" COC
"
" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Git coauthors autocomplete
"
command! -nargs=+ Gca :r!git log -n400 --pretty=format:"\%an <\%ae>" | grep -i '<args>' | head -1 | xargs echo "Co-authored-by:"

" AIRLINE
"
let g:airline_theme='onedark'
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline#extensions#tabline#show_splits = 0
let g:airline#extensions#tabline#show_tabs = 1
let g:airline#extensions#tabline#show_tab_nr = 0
let g:airline#extensions#tabline#show_tab_type = 0
let g:airline#extensions#tabline#show_close_button = 0

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

" THEME
"
colorscheme onedark

" Enable true colours in Neovim
if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif
