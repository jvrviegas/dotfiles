local bg, panel, fg, silver = '#101820', '#1b2833', '#E3E7EA', '#B4C2CE'
local function mode(accent)
  return {
    a = { fg = bg, bg = accent, gui = 'bold' },
    b = { fg = silver, bg = '#354756' },
    c = { fg = fg, bg = panel },
  }
end
return {
  normal = mode('#E58B65'), insert = mode('#A3BE8C'), visual = mode('#B9A0CF'),
  replace = mode('#E67D78'), command = mode('#E5C07B'), terminal = mode('#80C3BC'),
  inactive = { a = { fg = '#A2ADB5', bg = bg }, b = { fg = '#A2ADB5', bg = bg },
    c = { fg = '#A2ADB5', bg = bg } },
}
