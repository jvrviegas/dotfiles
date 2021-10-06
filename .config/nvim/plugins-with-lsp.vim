"Plugins managed by Plug 
set nocompatible              " be iMproved, required

call plug#begin()

Plug 'ervandew/supertab'
Plug 'preservim/nerdtree'
"Plug 'ms-jpq/chadtree', {'branch': 'chad', 'do': 'python3 -m chadtree deps'}
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'preservim/nerdcommenter'
Plug 'vim-airline/vim-airline'
Plug 'airblade/vim-gitgutter'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzy-native.nvim'
Plug 'editorconfig/editorconfig-vim'
Plug 'jiangmiao/auto-pairs'
Plug 'mg979/vim-visual-multi', {'branch': 'master'}
Plug 'tpope/vim-fugitive'
Plug 'ryanoasis/vim-devicons'

" Themes
Plug 'dracula/vim', {'as': 'dracula'}
Plug 'morhetz/gruvbox'
Plug 'arcticicestudio/nord-vim'
Plug 'yonlu/omni.vim'
"Plug 'nokobear/vim-colorscheme-edit'

" Javascript/Typescript and CSS Plugins
Plug 'sheerun/vim-polyglot'
Plug 'styled-components/vim-styled-components', { 'branch': 'main' }

" CoC Plugin
"Plug 'neoclide/coc.nvim', {'branch': 'release'}
"Plug 'ms-jpq/coq_nvim', {'branch': 'coq'}
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/nvim-cmp'

call plug#end()            " required
filetype plugin indent on    " required
"let g:dracula_colorterm = 0
let g:gruvbox_italic=1
colorscheme gruvbox
highlight Normal guibg=none
