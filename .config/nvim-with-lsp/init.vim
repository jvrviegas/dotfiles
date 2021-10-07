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

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * call StartUp()

autocmd BufEnter *.{js,jsx,ts,tsx} :syntax sync fromstart
autocmd BufLeave *.{js,jsx,ts,tsx} :syntax sync clear
" Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

if (has("termguicolors"))
  set termguicolors
endif

" PLUGINS
" ============================================
" my plugins config file path
let $MYPLUGINS = '~/.config/nvim/plugins.vim'

" load plugins managed by Plug
exe 'so '.$MYPLUGINS

" Create default mappings
let g:NERDCreateDefaultMappings = 1

" vim icons file type
set encoding=utf8
let g:airline_powerline_fonts = 1
let g:airline#extensions#branch#enabled=1
let g:blamer_enabled = 1

set splitright
set hidden
set number
set signcolumn=yes
set updatetime=100
"set relativenumber
set inccommand=split

" always set autoindenting on
set autoindent

" good when starting a new line
set smartindent

" fill tabls with spaces
set expandtab

" 4 spaces everywhere please!
set tabstop=4
set softtabstop=4
set shiftwidth=4

" don't wrap lines
set nowrap

" show line numbers
set number

" allow hidden buffers
set hidden

" use many undos
set undolevels=50

" do not highlight too long lines
"set synmaxcol=120

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

" set cursorline
set cursorline

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
nnoremap <leader>0 :source ~/.config/nvim/init.vim<cr>

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

" Toggle terminal on/off (neovim)
nnoremap <C-l> :call TermToggle(12)<CR>
inoremap <C-l> <Esc>:call TermToggle(12)<CR>
tnoremap <C-l> <C-\><C-n>:call TermToggle(12)<CR>

" Terminal go back to normal mode
tnoremap <Esc> <C-\><C-n>
tnoremap :q! <C-\><C-n>:q!<CR>

" Vim Telescope shortcuts
" Find files using Telescope command-line sugar.
nnoremap <C-p> <cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" Vim Fugitive shortcuts
nnoremap <leader>ds :Gdiffsplit<cr>

" NERDTree
nnoremap <leader>s :NERDTreeToggle<CR>
nnoremap <leader>mn :NERDTreeMirror<CR>
nnoremap <leader>r :NERDTreeFind<CR>

" Use CR to confirm completion on insert mode
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" load lua scripts
lua require('jvrviegas')

nnoremap <leader>vrc :lua require('jvrviegas.telescope').search_dotfiles()<CR>

hi! link GitLens Comment
