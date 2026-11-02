local M = {}

function M.setup()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local accent = vim.api.nvim_get_hl(0, { name = "Function", link = false })
  local mint = vim.g.colors_name == "forge-mint"
  local tokyo = (vim.g.colors_name or ""):find("tokyonight", 1, true)
  local background = mint and 0x0b110e or tokyo and 0x10121e or normal.bg or 0x16161e
  if tokyo or mint then
    local editor_background = mint and 0x050907 or 0x0d0f18
    vim.api.nvim_set_hl(0, "Normal", { fg = normal.fg or 0xc0caf5, bg = editor_background })
    vim.api.nvim_set_hl(0, "NormalNC", { fg = normal.fg or 0xc0caf5, bg = editor_background })
  end
  local accent_color = mint and 0x69e598 or tokyo and 0xbb9af7 or accent.fg or 0xbb9af7
  local border = mint and 0x203c2c or 0x414868
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
    ForgeBorder = { fg = border, bg = background },
    ForgeAccent = { fg = accent_color, bg = background, bold = true },
    ForgeMuted = { fg = 0x8993b4, bg = background },
    ForgeBadge = { fg = background, bg = accent_color, bold = true },
    ForgeTab = { fg = 0x8993b4, bg = background },
    ForgeTabActive = { fg = foreground, bg = 0x292e42, bold = true },
  }
  for name, value in pairs(groups) do
    vim.api.nvim_set_hl(0, name, value)
  end
  if mint then
    for _, name in ipairs({
      "NvimTreeFolderIcon",
      "NvimTreeOpenedFolderIcon",
      "NvimTreeClosedFolderIcon",
      "NvimTreeFolderName",
      "NvimTreeOpenedFolderName",
      "NvimTreeEmptyFolderName",
      "NvimTreeSymlinkFolderName",
      "NvimTreeRootFolder",
    }) do
      vim.api.nvim_set_hl(0, name, { fg = accent_color })
    end
  end
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = border, bg = background })
end

return M
