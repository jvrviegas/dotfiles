function! StartUp()
    if !argc() && !exists("s:std_in")
        NERDTree
    end
    if argc() && isdirectory(argv()[0]) && !exists("s:std_in")
        exe 'NERDTree' argv()[0]
        wincmd p
        ene
    end
endfunction

" Terminal Function
let g:term_buf = 0
let g:term_win = 0
function! TermToggle(height)
    if win_gotoid(g:term_win)
        hide
    else
        botright new
        exec "resize " . a:height
        try
            exec "buffer " . g:term_buf
        catch
            call termopen($SHELL, {"detach": 0})
            let g:term_buf = bufnr("")
            set nonumber
            set norelativenumber
            set signcolumn=no
        endtry
        startinsert!
        let g:term_win = win_getid()
    endif
endfunction

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * call StartUp()

autocmd BufEnter *.{js,jsx,ts,tsx} :syntax sync fromstart
autocmd BufLeave *.{js,jsx,ts,tsx} :syntax sync clear

" PLUGINS
" ============================================
" my plugins config file path
let $MYPLUGINS = '~/.config/nvim/plugins.vim'

" load plugins managed by Plug
exe 'so '.$MYPLUGINS

" Create default mappings
let g:NERDCreateDefaultMappings = 1

set hidden
set number
set signcolumn=yes
"set relativenumber
set inccommand=split

" always set autoindenting on
set autoindent

" good when starting a new line
set smartindent

" fill tabls with spaces
set expandtab

" 2 spaces everywhere please!
set tabstop=2
set softtabstop=2
set shiftwidth=2

" don't wrap lines
set nowrap

" show line numbers
set number

" allow hidden buffers
set hidden

" use many undos
set undolevels=50

" do not highlight too long lines
set synmaxcol=120

" SCROLLING
" ============================================
" show more lines around cursor when at the edge of file
set scrolloff=8
set sidescrolloff=8

" SEARCH
" ======================================
" ignore case when searching
set ignorecase

" ignore case if search pattern is all lowercase, case-sensitive otherwise
set smartcase

" highlight search when typing
set incsearch

" highlight search terms
set nohlsearch

" do not highlight when vim starts
nohls

set timeout
set timeoutlen=400

" REMAPS 
" set leader key to space
let mapleader=" "

" set leader + ev to open nvim config file
nnoremap <leader>ev :vsplit ~/.config/nvim/init.vim<cr>

" set leader + sv to source nvim config
nnoremap <leader>sv :source ~/.config/nvim/init.vim<cr>

" set leader + A to insert at the end of the line
nnoremap <leader>aa A

" set leader + w to write buffers
nnoremap <leader>w :w<cr>

" set leader + q to quit file
nnoremap <leader>q :q<cr>

" set leader + sl to insert new line below with 2 spaces above 
nnoremap <leader>nlb o<esc>o

" set leader + semicolons to add semicolons at the end
nnoremap <leader>; A;<esc>

" set leader + x to cut selected to clipboard
vnoremap <leader>x "+x

" set leader + c to copy selected to clipboard
vnoremap <leader>c "+y

" set leader + v to paste from clipboard
nnoremap <leader>v "+gP

" set keys to copy line and paste above or below
nnoremap <leader>J yyp
nnoremap <leader>K yyP

" remap gd to use coc-definition plugin
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)

" Toggle terminal on/off (neovim)
nnoremap <C-l> :call TermToggle(12)<CR>
inoremap <C-l> <Esc>:call TermToggle(12)<CR>
tnoremap <C-l> <C-\><C-n>:call TermToggle(12)<CR>

" Terminal go back to normal mode
tnoremap <Esc> <C-\><C-n>
tnoremap :q! <C-\><C-n>:q!<CR>

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

" toggle NERDTree sidebar
nnoremap <leader>s :NERDTreeToggle<cr>
let NERDTreeIgnore = ['\.pyc$', '__pycache', 'deps', '_build', 'node_modules', 'bower_components']
let g:NERDTreeWinSize=40

let g:ctrlp_working_path_mode = 'ra'
set wildignore+=*/tmp/*,*/build/*,*/dist/*,node_modules,*.so,*.swp,*.zip

" CoC Configuration
let g:coc_global_extensions = [
  \ 'coc-tsserver'
  \ ]

if isdirectory('./node_modules') && isdirectory('./node_modules/prettier')
  let g:coc_global_extensions += ['coc-prettier']
endif

if isdirectory('./node_modules') && isdirectory('./node_modules/eslint')
  let g:coc_global_extensions += ['coc-eslint']
endif

