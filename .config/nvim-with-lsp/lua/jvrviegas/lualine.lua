local lualine = require('lualine')
local lsp_status = require('lsp-status')

local options = {
    theme = 'gruvbox',
}

local sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch'},
    lualine_c = { { 'filename', path = 1 }, 'lsp_progress' },
    lualine_x = {"os.data('%a')", 'data', lsp_status.status, 'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
}

lualine.setup {
    options = options,
    sections = sections
}
