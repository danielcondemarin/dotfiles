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

" tabs
map <Leader>t :tabnew<CR>

" searching text (ag)
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

" Snippets
" NOTE: You can use other key to expand snippet.
" expand
imap <expr> <C-y>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-y>'
smap <expr> <C-y>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-y>'
" jump forward or backward
imap <expr> <C-j>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<C-j>'
smap <expr> <C-j>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<C-j>'
imap <expr> <C-l>   vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<C-l>'
smap <expr> <C-l>   vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<C-l>'
" select or cut text to use as $tm_selected_text in the next snippet.
" see https://github.com/hrsh7th/vim-vsnip/pull/50
" nmap        s   <Plug>(vsnip-select-text)
" xmap        s   <Plug>(vsnip-select-text)
" nmap        S   <Plug>(vsnip-cut-text)
" xmap        S   <Plug>(vsnip-cut-text)
