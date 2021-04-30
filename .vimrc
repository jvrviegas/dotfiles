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

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * call StartUp()

" PLUGINS
" ============================================
" my plugins config file path
let $MYPLUGINS = '~/.vim/plugins.vim'

" load plugins managed by Vundle
exe 'so '.$MYPLUGINS

syntax enable
syntax on

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
set scrolloff=3
set sidescrolloff=5


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

" hide search highlight
nnoremap <silent> <leader>0 :nohls<cr>

" enable column signs
set signcolumn=yes

" REMAPS

" toggle NERDTree sidebar
map <leader>s :NERDTreeToggle<cr>
let NERDTreeIgnore = ['\.pyc$', '__pycache', 'deps', '_build', 'node_modules', 'bower_components']
let g:NERDTreeWinSize=40

let g:ctrlp_working_path_mode = 'ra'
set wildignore+=*/tmp/*,*/build/*,*/dist/*,node_modules,*.so,*.swp,*.zip
