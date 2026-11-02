local M = {}

function M.setup()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local accent = vim.api.nvim_get_hl(0, { name = "Function", link = false })
  local tokyo = (vim.g.colors_name or ""):find("tokyonight", 1, true)
  local background = tokyo and 0x171e2a or normal.bg or 0x16161e
  if tokyo then
    vim.api.nvim_set_hl(0, "Normal", { fg = normal.fg or 0xc0caf5, bg = 0x10151f })
    vim.api.nvim_set_hl(0, "NormalNC", { fg = normal.fg or 0xc0caf5, bg = 0x10151f })
  end
  local accent_color = tokyo and 0x83d9b3 or accent.fg or 0xbb9af7
  local foreground = normal.fg or 0xc0caf5
  local groups = {
    ForgeModeNormal = { fg = background, bg = accent_color, bold = true },
    ForgeModeInsert = { fg = background, bg = 0x9ece6a, bold = true },
    ForgeModeVisual = { fg = background, bg = 0xe0af68, bold = true },
    ForgeModeReplace = { fg = background, bg = 0xf7768e, bold = true },
    ForgeError = { fg = 0xf7768e, bg = background },
    ForgeWarning = { fg = 0xe0af68, bg = background },
    ForgePanel = { fg = foreground, bg = background },
    ForgeSurface = { fg = foreground, bg = background },
    ForgeBorder = { fg = 0x354253, bg = background },
    ForgeAccent = { fg = accent_color, bg = background, bold = true },
    ForgeMuted = { fg = 0x8993b4, bg = background },
    ForgeBadge = { fg = background, bg = accent_color, bold = true },
    ForgeTab = { fg = 0x8993b4, bg = background },
    ForgeTabActive = { fg = foreground, bg = 0x292e42, bold = true },
  }
  for name, value in pairs(groups) do
    vim.api.nvim_set_hl(0, name, value)
  end
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = 0x354253, bg = background })
end

return M
