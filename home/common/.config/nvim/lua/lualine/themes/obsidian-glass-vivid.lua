local bg, panel, fg, silver = '#08090A', '#151719', '#E4E9E8', '#BACACD'
local function mode(accent)
  return {
    a = { fg = bg, bg = accent, gui = 'bold' },
    b = { fg = silver, bg = '#303538' },
    c = { fg = fg, bg = panel },
  }
end
return {
  normal = mode(silver), insert = mode('#98C379'), visual = mode('#C678DD'),
  replace = mode('#E06C75'), command = mode('#E5C07B'), terminal = mode('#56B6C2'),
  inactive = { a = { fg = '#959EA2', bg = bg }, b = { fg = '#959EA2', bg = bg },
    c = { fg = '#959EA2', bg = bg } },
}
