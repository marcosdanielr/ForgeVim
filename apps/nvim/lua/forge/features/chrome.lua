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

function M.tabline()
  local count = require("forge.features.panels.windows").get("agents")
      and vim.t.forge_active_agent_count
    or nil
  local agent_label = "Agents" .. (count and (" " .. count) or "")
  local controls = vim.o.columns >= 120
      and ("  Files [Ctrl B]  |  " .. agent_label .. " [Space pa]  |  Chat [Space pc]  |  Terminal [Ctrl `]  |  F1 Help")
    or "  F1 Help  |  Space Space Commands"
  local tabs = ""
  for index, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local active = tab == vim.api.nvim_get_current_tabpage()
    tabs = tabs
      .. (active and "%#TabLineSel#" or "%#TabLine#")
      .. "%"
      .. index
      .. "T "
      .. index
      .. " %T"
  end
  return "%#TabLineSel# FORGE %#TabLine#" .. controls .. "%=" .. tabs
end

function M.setup()
  vim.opt.showtabline = 2
  vim.opt.tabline = "%!v:lua.require('forge.features.chrome').tabline()"
  vim.opt.laststatus = 3
  vim.opt.statusline = "%!v:lua.require('forge.features.chrome').statusline()"
end

return M
