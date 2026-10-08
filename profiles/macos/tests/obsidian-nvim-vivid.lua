vim.cmd.colorscheme('obsidian-glass-vivid')
local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end
local colors = {
  Keyword = 0xC678DD, Function = 0x61AFEF, Type = 0xE5C07B,
  String = 0x98C379, Number = 0xD19A66, DiagnosticError = 0xE06C75,
  ['@lsp.type.parameter'] = 0x56B6C2, ['@markup.heading'] = 0xE5C07B,
  NeoTreeGitModified = 0xE5C07B, NeoTreeGitUntracked = 0x56B6C2,
}
for name, color in pairs(colors) do assert(hl(name).fg == color, name) end
assert(vim.g.colors_name == 'obsidian-glass-vivid')
assert(hl('Normal').bg == 0x08090A)
assert(vim.g.terminal_color_4 == '#61AFEF')
assert(require('lualine.themes.obsidian-glass-vivid').insert.a.bg == '#98C379')
-- A/B switching must restore the quieter semantic palette without a restart.
vim.cmd.colorscheme('obsidian-glass')
assert(hl('Function').fg == 0x8DBBE9)
assert(hl('Keyword').fg == 0xC4A0DD)
print('Vivid palette and switching back to soft passed')
