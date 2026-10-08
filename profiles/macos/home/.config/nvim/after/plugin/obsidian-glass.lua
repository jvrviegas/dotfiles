-- macOS profile overlay: leave the separately maintained init.lua untouched.
local supported = { ['obsidian-glass'] = true, ['obsidian-glass-vivid'] = true, ['golden-gate-after-dark'] = true }
local function selected()
  local f = io.open(vim.fn.expand('~/.config/theme/current'), 'r')
  if not f then return nil end
  local name = f:read('*l')
  f:close()
  return supported[name] and name or nil
end
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('ObsidianGlassStatusline', { clear = true }),
  pattern = { 'obsidian-glass', 'obsidian-glass-vivid', 'golden-gate-after-dark' },
  callback = function(event)
    local ok, lualine = pcall(require, 'lualine')
    if ok then lualine.setup({ options = { theme = event.match } }) end
  end,
})
local function apply()
  local name = selected()
  if name then vim.cmd.colorscheme(name) end
end
apply()
-- Runs after startup plugins finish, retaining existing statusline sections.
if vim.v.vim_did_enter == 0 then
  vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = apply })
end
