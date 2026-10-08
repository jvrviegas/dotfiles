-- Run with nvim --headless -u NONE after putting the profile on runtimepath.
vim.cmd.colorscheme('obsidian-glass')
local function highlight(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end
local roles = {
  Keyword = 0xC4A0DD, Function = 0x8DBBE9, Type = 0xE2C079,
  String = 0x9BCB95, Number = 0xD99580, Identifier = 0xE4E9E8,
  ['@lsp.type.parameter'] = 0x7FC8B7, ['@markup.heading'] = 0xE2C079,
  ['@markup.raw'] = 0x7FC8B7, ['@markup.raw.block'] = 0xE4E9E8,
  NeoTreeDirectoryName = 0x8DBBE9, NeoTreeGitModified = 0xE2C079,
  NeoTreeGitUntracked = 0x7FC8B7, DiagnosticError = 0xE68A8A,
}
for name, color in pairs(roles) do
  assert(highlight(name).fg == color, 'wrong semantic colour: ' .. name)
end
assert(highlight('Normal').bg == 0x08090A, 'background must stay unchanged')
assert(highlight('NeoTreeCursorLine').bg == 0x303F4B)
assert(highlight('NeoTreeCursorLine').bold)
assert(highlight('Title').bold)
assert(highlight('Underlined').underline)
-- Prevent keywords/functions/types being collapsed back to the same silver.
local seen = {}
for _, name in ipairs({ 'Keyword', 'Function', 'Type', 'String', 'Number', 'Identifier' }) do
  local color = highlight(name).fg
  assert(not seen[color], 'indistinguishable semantic roles: ' .. name)
  seen[color] = true
end
print('Neovim semantic roles, Markdown and file-tree checks passed')
