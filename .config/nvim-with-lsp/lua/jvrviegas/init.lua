-- initialize global object for config
global = {}

require('jvrviegas.telescope')
--require('jvrviegas.blamer')
require('jvrviegas.lsp')
require('jvrviegas.autopairs')
require('jvrviegas.cmp')
require('jvrviegas.lualine')
require('jvrviegas.treesitter')
--require('jvrviegas.saga')
require('jvrviegas.gitsigns')
require('jvrviegas.kommentary')
require('jvrviegas.indent-blankline')

vim.cmd [[let g:blamer_enabled = 1]]
vim.cmd [[let g:blamer_delay = 500]]

--vim.api.nvim_command [[autocmd CursorHold   * lua require'jvrviegas.blamer'.blameVirtText()]]
--vim.api.nvim_command [[autocmd CursorMoved  * lua require'jvrviegas.blamer'.clearBlameVirtText()]]
--vim.api.nvim_command [[autocmd CursorMovedI * lua require'jvrviegas.blamer'.clearBlameVirtText()]]
