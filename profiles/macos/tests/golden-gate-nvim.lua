-- Run with nvim --headless -u NONE with the macOS overlay on runtimepath.
vim.cmd.colorscheme('golden-gate-after-dark')
local function highlight(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end
for _, name in ipairs({
  'Normal', 'NormalNC', 'NormalFloat', 'FloatBorder', 'FloatTitle',
  'SignColumn', 'FoldColumn', 'EndOfBuffer', 'TabLineFill',
  'TelescopeNormal', 'TelescopeBorder', 'NeoTreeNormal', 'NeoTreeNormalNC',
  'NeoTreeEndOfBuffer', 'Pmenu',
}) do
  assert(highlight(name).bg == nil, 'opaque surface: ' .. name)
end
assert(highlight('Normal').fg == 0xE3E7EA)
assert(highlight('Function').fg == 0x7CB4D8)
assert(highlight('Keyword').fg == 0xB9A0CF)
assert(highlight('Visual').bg == 0x3A5369)
assert(highlight('Search').bg == 0x3A5369)
assert(highlight('NeoTreeCursorLine').bg == 0x2D485E)
assert(require('lualine.themes.golden-gate-after-dark').normal.a.bg == '#E58B65')
-- Reloading must not bring back opaque surfaces.
vim.cmd.colorscheme('golden-gate-after-dark')
assert(highlight('Normal').bg == nil)
print('Golden Gate Neovim transparency and semantic colours passed')
