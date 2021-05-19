"Plugins managed by Plug 
set nocompatible              " be iMproved, required

call plug#begin()

Plug 'ervandew/supertab'
Plug 'preservim/nerdtree'
Plug 'preservim/nerdcommenter'
Plug 'kien/ctrlp.vim'
Plug 'vim-airline/vim-airline'
Plug 'airblade/vim-gitgutter'
Plug 'editorconfig/editorconfig-vim'
Plug 'sheerun/vim-polyglot'
Plug 'jiangmiao/auto-pairs'
Plug 'mg979/vim-visual-multi', {'branch': 'master'}
Plug 'tpope/vim-fugitive'
Plug 'codota/tabnine-vim'

" Themes
Plug 'dracula/vim', {'as': 'dracula'}
Plug 'morhetz/gruvbox'
"Plug 'nokobear/vim-colorscheme-edit'

" Javascript/Typescript and CSS Plugins
"Plug 'styled-components/vim-styled-components', { 'branch': 'main' }

" CoC Plugin
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()            " required
filetype plugin indent on    " required
let g:dracula_colorterm = 0
colorscheme dracula
highlight Normal guibg=none
