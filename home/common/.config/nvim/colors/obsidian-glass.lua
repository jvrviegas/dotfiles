-- Obsidian Glass: graphite, reflective silver and restrained semantic colour.
vim.cmd('highlight clear')
vim.o.background = 'dark'
vim.o.termguicolors = true
vim.g.colors_name = 'obsidian-glass'

local c = {
  bg = '#08090A', panel = '#151719', selection = '#424C52', muted = '#959EA2',
  fg = '#E4E9E8', silver = '#BACACD', red = '#E68A8A', green = '#9BCB95',
  yellow = '#E2C079', blue = '#8DBBE9', purple = '#C4A0DD', cyan = '#7FC8B7',
  peach = '#D99580',
}
local function hl(name, value) vim.api.nvim_set_hl(0, name, value) end
local groups = {
  Normal = { fg = c.fg, bg = c.bg }, NormalNC = { fg = c.fg, bg = c.bg },
  NormalFloat = { fg = c.fg, bg = c.panel }, FloatBorder = { fg = c.muted, bg = c.panel },
  FloatTitle = { fg = c.silver, bg = c.panel, bold = true },
  SignColumn = { bg = c.bg }, LineNr = { fg = c.muted }, CursorLineNr = { fg = c.yellow, bold = true },
  CursorLine = { bg = c.panel }, CursorColumn = { bg = c.panel },
  Cursor = { fg = c.bg, bg = c.silver }, ColorColumn = { bg = c.panel },
  Visual = { fg = '#EFF3F2', bg = c.selection }, Search = { fg = c.fg, bg = c.selection },
  IncSearch = { fg = c.bg, bg = c.silver }, CurSearch = { fg = c.bg, bg = c.silver },
  MatchParen = { fg = c.silver, bg = c.selection, bold = true },
  WinSeparator = { fg = c.selection }, NonText = { fg = '#50585C' },
  Whitespace = { fg = '#50585C' }, EndOfBuffer = { fg = c.bg },
  Folded = { fg = c.muted, bg = c.panel }, FoldColumn = { fg = c.muted, bg = c.bg },
  StatusLine = { fg = c.fg, bg = c.panel }, StatusLineNC = { fg = c.muted, bg = c.bg },
  TabLine = { fg = c.muted, bg = c.panel }, TabLineSel = { fg = c.bg, bg = c.silver },
  TabLineFill = { bg = c.bg }, Pmenu = { fg = c.fg, bg = c.panel },
  PmenuSel = { fg = '#EFF3F2', bg = c.selection, bold = true }, PmenuSbar = { bg = c.selection }, PmenuThumb = { bg = c.muted },
  Comment = { fg = c.muted, italic = true }, Constant = { fg = c.cyan }, String = { fg = c.green },
  Character = { fg = c.green }, Number = { fg = c.peach }, Boolean = { fg = c.peach, bold = true },
  Identifier = { fg = c.fg }, Function = { fg = c.blue, bold = true },
  Statement = { fg = c.purple, bold = true }, Keyword = { fg = c.purple, bold = true },
  Operator = { fg = c.silver }, PreProc = { fg = c.purple }, Type = { fg = c.yellow, bold = true },
  Special = { fg = c.cyan }, Delimiter = { fg = c.silver },
  Todo = { fg = c.yellow, bg = c.panel, bold = true }, Error = { fg = c.red },
  ErrorMsg = { fg = c.red }, WarningMsg = { fg = c.yellow }, Directory = { fg = c.blue, bold = true },
  Title = { fg = c.yellow, bold = true }, Underlined = { fg = c.blue, underline = true }, MoreMsg = { fg = c.green }, Question = { fg = c.cyan },
  ObsidianParameter = { fg = c.cyan }, ObsidianProperty = { fg = c.silver },
  ObsidianInlineCode = { fg = c.cyan, bg = c.panel },
  ObsidianCodeBlock = { fg = c.fg, bg = c.panel },
  ObsidianListMarker = { fg = c.yellow, bold = true },
  ObsidianStrong = { fg = c.fg, bold = true }, ObsidianEmphasis = { fg = c.cyan, italic = true },
  ObsidianQuote = { fg = c.muted, italic = true },
  DiffAdd = { bg = '#18251D' }, DiffChange = { bg = '#1B252D' },
  DiffDelete = { fg = c.red, bg = '#2C1B1D' }, DiffText = { bg = '#303C45' },
  TelescopeNormal = { fg = c.fg, bg = c.panel }, TelescopeBorder = { fg = c.muted, bg = c.panel },
  TelescopeSelection = { fg = '#EFF3F2', bg = c.selection, bold = true }, TelescopeMatching = { fg = c.silver, bold = true },
  TelescopePromptTitle = { fg = c.bg, bg = c.silver },
  NeoTreeNormal = { fg = c.fg, bg = c.panel }, NeoTreeNormalNC = { fg = c.fg, bg = c.panel },
  NeoTreeDirectoryName = { fg = c.blue, bold = true }, NeoTreeDirectoryIcon = { fg = c.blue },
  NeoTreeRootName = { fg = c.yellow, bold = true },
  NeoTreeFileName = { fg = c.fg }, NeoTreeFileNameOpened = { fg = c.cyan, bold = true },
  NeoTreeCursorLine = { fg = '#EFF3F2', bg = '#303F4B', bold = true },
  NeoTreeGitAdded = { fg = c.green }, NeoTreeGitModified = { fg = c.yellow },
  NeoTreeGitDeleted = { fg = c.red }, NeoTreeGitConflict = { fg = c.red, bold = true },
  NeoTreeGitUntracked = { fg = c.cyan }, NeoTreeGitUnstaged = { fg = c.yellow },
  NeoTreeGitStaged = { fg = c.green }, NeoTreeGitIgnored = { fg = c.muted },
  NeoTreeIndentMarker = { fg = '#50585C' }, NeoTreeWinSeparator = { fg = c.selection },
  NeoTreeEndOfBuffer = { fg = c.panel, bg = c.panel },
  GitSignsAdd = { fg = c.green }, GitSignsChange = { fg = c.blue }, GitSignsDelete = { fg = c.red },
}
for name, value in pairs(groups) do hl(name, value) end
for kind, color in pairs({ Error = c.red, Warn = c.yellow, Info = c.blue, Hint = c.cyan, Ok = c.green }) do
  hl('Diagnostic' .. kind, { fg = color })
  hl('DiagnosticSign' .. kind, { fg = color })
  hl('DiagnosticVirtualText' .. kind, { fg = color, bg = c.panel })
  hl('DiagnosticUnderline' .. kind, { sp = color, undercurl = true })
end
local links = {
  ['@comment'] = 'Comment', ['@string'] = 'String', ['@number'] = 'Number',
  ['@boolean'] = 'Boolean', ['@constant'] = 'Constant', ['@constant.builtin'] = 'Constant',
  ['@variable'] = 'Identifier', ['@variable.builtin'] = 'Special', ['@variable.parameter'] = 'ObsidianParameter',
  ['@variable.member'] = 'ObsidianProperty',
  ['@function'] = 'Function', ['@function.call'] = 'Function', ['@function.builtin'] = 'Function',
  ['@function.method'] = 'Function', ['@function.method.call'] = 'Function',
  ['@keyword'] = 'Keyword', ['@operator'] = 'Operator', ['@type'] = 'Type',
  ['@type.builtin'] = 'Type', ['@property'] = 'ObsidianProperty', ['@tag'] = 'Type',
  ['@tag.attribute'] = 'ObsidianParameter', ['@tag.delimiter'] = 'Delimiter',
  ['@punctuation'] = 'Delimiter', ['@markup.heading'] = 'Title', ['@markup.link'] = 'Underlined',
  ['@markup.link.label'] = 'Underlined', ['@markup.link.url'] = 'Underlined',
  ['@markup.raw'] = 'ObsidianInlineCode', ['@markup.raw.block'] = 'ObsidianCodeBlock',
  ['@markup.list'] = 'ObsidianListMarker', ['@markup.strong'] = 'ObsidianStrong',
  ['@markup.italic'] = 'ObsidianEmphasis', ['@markup.quote'] = 'ObsidianQuote',
  markdownH1 = 'Title', markdownH2 = 'Title', markdownH3 = 'Title',
  markdownH4 = 'Title', markdownH5 = 'Title', markdownH6 = 'Title',
  markdownHeadingDelimiter = 'Title', markdownCode = 'ObsidianInlineCode',
  markdownCodeBlock = 'ObsidianCodeBlock', markdownCodeDelimiter = 'Delimiter',
  markdownUrl = 'Underlined', markdownLinkText = 'Underlined', markdownListMarker = 'ObsidianListMarker',
  ['@lsp.type.variable'] = 'Identifier', ['@lsp.type.parameter'] = 'ObsidianParameter',
  ['@lsp.type.property'] = 'ObsidianProperty', ['@lsp.type.function'] = 'Function', ['@lsp.type.method'] = 'Function',
  ['@lsp.type.class'] = 'Type', ['@lsp.type.interface'] = 'Type', ['@lsp.type.enum'] = 'Type',
  LspReferenceText = 'Visual', LspReferenceRead = 'Visual', LspReferenceWrite = 'Visual',
}
for name, target in pairs(links) do hl(name, { link = target }) end
local ansi = { '#151719', c.red, c.green, c.yellow, c.blue, c.purple, c.cyan, '#D3DAD9',
  '#707A7E', '#E6A3A3', '#B0D7BA', '#E7CB91', '#ADCDEE', '#CEB4E4', '#A0D8DE', '#EFF3F2' }
for i, color in ipairs(ansi) do vim.g['terminal_color_' .. (i - 1)] = color end
