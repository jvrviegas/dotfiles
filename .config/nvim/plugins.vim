"Plugins managed by Plug 
set nocompatible              " be iMproved, required

call plug#begin('~/.vim/plugged')

Plug 'ervandew/supertab'
Plug 'preservim/nerdtree'
Plug 'kien/ctrlp.vim'
Plug 'vim-airline/vim-airline'
Plug 'airblade/vim-gitgutter'
Plug 'editorconfig/editorconfig-vim'
Plug 'sheerun/vim-polyglot'
Plug 'dracula/vim', {'as': 'dracula'}

" Javascript/Typescript and CSS Plugins
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'
Plug 'styled-components/vim-styled-components', { 'branch': 'main' }

" CoC Plugin
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()            " required
colorscheme dracula
filetype plugin indent on    " required

