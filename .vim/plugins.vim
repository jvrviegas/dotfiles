"Plugins managed by Vundle 
set nocompatible              " be iMproved, required
filetype off                  " required
set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin()
Plugin 'VundleVim/Vundle.vim'

Plugin 'ervandew/supertab'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/nerdcommenter'
Plugin 'kien/ctrlp.vim'
Plugin 'vim-airline/vim-airline'
Plugin 'airblade/vim-gitgutter'
Plugin 'editorconfig/editorconfig-vim'
Plugin 'sheerun/vim-polyglot'
Plugin 'gruvbox-community/gruvbox'
Plugin 'Quramy/tsuquyomi'
Plugin 'eslint/eslint'
Plugin 'codota/tabnine-vim'

call vundle#end()            " required
colorscheme gruvbox
filetype plugin indent on    " required
