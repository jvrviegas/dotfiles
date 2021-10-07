local configs = require('nvim-treesitter.configs')
local parsers = require('nvim-treesitter.parsers')

configs.setup {
    highlight = {
        enable = true,
        disable = {},
    },
    indent = {
        enable = false,
        disable = {},
    },
    ensure_installed = {
        "tsx",
        "json",
        "html",
        "scss",
        "css",
        "javascript"
    }
}

local parser_config = parsers.get_parser_configs()
parser_config.tsx.used_by = { "javascript", "typescript.tsx" }
