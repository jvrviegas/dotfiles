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

" Themes
Plug 'dracula/vim', {'as': 'dracula'}
Plug 'morhetz/gruvbox'
Plug 'nokobear/vim-colorscheme-edit'

" Javascript/Typescript and CSS Plugins
"Plug 'pangloss/vim-javascript'
"Plug 'leafgarland/typescript-vim'
"Plug 'peitalin/vim-jsx-typescript'
"Plug 'styled-components/vim-styled-components', { 'branch': 'main' }

" CoC Plugin
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()            " required
filetype plugin indent on    " required
colorscheme dracula
