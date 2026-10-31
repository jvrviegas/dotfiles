local bg, panel, fg, silver = '#08090A', '#151719', '#E4E9E8', '#BACACD'
local function mode(accent)
  return {
    a = { fg = bg, bg = accent, gui = 'bold' },
    b = { fg = silver, bg = '#303538' },
    c = { fg = fg, bg = panel },
  }
end
return {
  normal = mode(silver), insert = mode('#9BCB95'), visual = mode('#C4A0DD'),
  replace = mode('#E68A8A'), command = mode('#E2C079'), terminal = mode('#7FC8B7'),
  inactive = { a = { fg = '#959EA2', bg = bg }, b = { fg = '#959EA2', bg = bg },
    c = { fg = '#959EA2', bg = bg } },
}
