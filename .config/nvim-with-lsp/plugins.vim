"Plugins managed by Plug 
set nocompatible              " be iMproved, required

call plug#begin()

Plug 'preservim/nerdtree'
"Plug 'ms-jpq/chadtree', {'branch': 'chad', 'do': 'python3 -m chadtree deps'}
Plug 'Xuyuanp/nerdtree-git-plugin'
"Plug 'preservim/nerdcommenter'
Plug 'b3nj5m1n/kommentary'
Plug 'hoob3rt/lualine.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzy-native.nvim'
Plug 'editorconfig/editorconfig-vim'
"Plug 'jiangmiao/auto-pairs'
Plug 'windwp/nvim-autopairs'
Plug 'mg979/vim-visual-multi', {'branch': 'master'}
Plug 'tpope/vim-fugitive'
Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
Plug 'windwp/nvim-ts-autotag'
Plug 'lewis6991/gitsigns.nvim'
Plug 'APZelos/blamer.nvim'
Plug 'lukas-reineke/indent-blankline.nvim'

" Icons
Plug 'ryanoasis/vim-devicons'
Plug 'kyazdani42/nvim-web-devicons'

" Themes
Plug 'dracula/vim', {'as': 'dracula'}
"Plug 'morhetz/gruvbox'
Plug 'rktjmp/lush.nvim'
Plug 'ellisonleao/gruvbox.nvim'
Plug 'arcticicestudio/nord-vim'
Plug 'yonlu/omni.vim'
Plug 'folke/tokyonight.nvim'
"Plug 'nokobear/vim-colorscheme-edit'

" Syntax Plugins
"Plug 'sheerun/vim-polyglot'
Plug 'styled-components/vim-styled-components', { 'branch': 'main' }

" Completion Plugins
" Plug 'hrsh7th/nvim-compe'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'ray-x/cmp-treesitter'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'tzachar/cmp-tabnine', { 'do': './install.sh' }
Plug 'hrsh7th/nvim-cmp'
Plug 'saadparwaiz1/cmp_luasnip' " Snippets source for nvim-cmp
Plug 'L3MON4D3/LuaSnip' " Snippets plugin

" LSP Plugins
"Plug 'ms-jpq/coq_nvim', { 'branch': 'coq' }
Plug 'neovim/nvim-lspconfig'
Plug 'glepnir/lspsaga.nvim'
Plug 'onsails/lspkind-nvim'
Plug 'nvim-lua/lsp-status.nvim'
Plug 'arkav/lualine-lsp-progress'
" Plug 'jose-elias-alvarez/null-ls.nvim'
" Plug 'jose-elias-alvarez/nvim-lsp-ts-utils'

call plug#end()            " required
filetype plugin indent on    " required
"let g:dracula_colorterm = 0
let g:gruvbox_italic=1
set background=dark
colorscheme gruvbox
highlight Normal guibg=none
