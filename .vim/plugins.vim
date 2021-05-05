"Plugins managed by Vundle 
set nocompatible              " be iMproved, required

call plug#begin('~/.vim/plugged')
Plug 'VundleVim/Vundle.vim'

Plug 'ervandew/supertab'
Plug 'scrooloose/nerdtree'
Plug 'scrooloose/nerdcommenter'
Plug 'kien/ctrlp.vim'
Plug 'vim-airline/vim-airline'
Plug 'airblade/vim-gitgutter'
Plug 'editorconfig/editorconfig-vim'
Plug 'sheerun/vim-polyglot'
Plug 'gruvbox-community/gruvbox'
Plug 'Quramy/tsuquyomi'
Plug 'eslint/eslint'
Plug 'codota/tabnine-vim'

call plug#end()            " required
colorscheme gruvbox
filetype plugin indent on    " required
