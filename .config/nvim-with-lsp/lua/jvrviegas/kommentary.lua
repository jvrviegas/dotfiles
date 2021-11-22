require('kommentary.config')

vim.api.nvim_set_keymap("n", "<leader>c<leader>", "<Plug>kommentary_line_default", {})
vim.api.nvim_set_keymap("n", "<leader>c", "<Plug>kommentary_motion_default", {})
vim.api.nvim_set_keymap("v", "<leader>c<leader>", "<Plug>kommentary_visual_default<C-c>", {})
