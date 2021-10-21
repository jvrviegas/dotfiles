"Plugins managed by Plug 
set nocompatible              " be iMproved, required

call plug#begin()

Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'preservim/nerdcommenter'
Plug 'hoob3rt/lualine.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzy-native.nvim'
Plug 'editorconfig/editorconfig-vim'
Plug 'jiangmiao/auto-pairs'
Plug 'mg979/vim-visual-multi', {'branch': 'master'}
Plug 'tpope/vim-fugitive'
Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
Plug 'tzachar/cmp-tabnine', { 'do': './install.sh' }
Plug 'lewis6991/gitsigns.nvim'
Plug 'APZelos/blamer.nvim'

" Icons
Plug 'ryanoasis/vim-devicons'
Plug 'kyazdani42/nvim-web-devicons'

" Themes
Plug 'dracula/vim', {'as': 'dracula'}
Plug 'rktjmp/lush.nvim'
Plug 'ellisonleao/gruvbox.nvim'
Plug 'arcticicestudio/nord-vim'
Plug 'yonlu/omni.vim'

" Javascript/Typescript and CSS Syntax Plugins
Plug 'styled-components/vim-styled-components', { 'branch': 'main' }

" LSP Plugins
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-compe'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'ray-x/cmp-treesitter'
Plug 'saadparwaiz1/cmp_luasnip' " Snippets source for nvim-cmp
Plug 'L3MON4D3/LuaSnip' " Snippets plugin
Plug 'glepnir/lspsaga.nvim'
Plug 'onsails/lspkind-nvim'
Plug 'nvim-lua/lsp-status.nvim'

call plug#end()            " required
filetype plugin indent on    " required
"let g:dracula_colorterm = 0
"let g:gruvbox_italic=1
set background=dark
colorscheme gruvbox
highlight Normal guibg=none
