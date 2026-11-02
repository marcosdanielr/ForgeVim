local M = {}
local modes = {
  n = "NORMAL",
  i = "INSERT",
  v = "VISUAL",
  V = "VISUAL LINE",
  c = "COMMAND",
  t = "TERMINAL",
  R = "REPLACE",
}

function M.statusline()
  local mode = modes[vim.fn.mode()] or "VISUAL"
  local name = vim.bo.filetype == "forge-workspace" and "Workspace" or "%f %m%r"
  return "%#StatusLine#  FORGE  |  "
    .. mode
    .. "  |  "
    .. name
    .. "%= Space Space commands  |  Space uw workspace  |  %l:%c  "
end

function M.setup()
  vim.opt.laststatus = 3
  vim.opt.statusline = "%!v:lua.require('forge.features.chrome').statusline()"
end

return M
