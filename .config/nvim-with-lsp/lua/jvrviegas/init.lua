require('jvrviegas.telescope')
require('jvrviegas.blamer')
require('jvrviegas.lsp')
require('jvrviegas.cmp')
--require('jvrviegas.saga')

vim.api.nvim_command [[autocmd CursorHold   * lua require'jvrviegas.blamer'.blameVirtText()]]
vim.api.nvim_command [[autocmd CursorMoved  * lua require'jvrviegas.blamer'.clearBlameVirtText()]]
vim.api.nvim_command [[autocmd CursorMovedI * lua require'jvrviegas.blamer'.clearBlameVirtText()]]