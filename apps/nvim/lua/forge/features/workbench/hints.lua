-- Shortcut hints are cached outside redraw; saved mappings remain authoritative.
local M = {}
local keys = {}
local commands = {
  activity = "ForgeNavigation",
  files = "ForgeTree",
  agents = "ForgeAgents",
  chat = "ForgeChat",
  logs = "ForgePanelLogs",
  terminal = "ForgeTerminal",
}

function M.refresh()
  local saved = require("forge.core.state").read().keymaps or {}
  for _, action in ipairs(require("forge.core.actions")) do
    local configured = saved[action.command] or action.keys
    local key = configured[1] or "Unbound"
    if action.command == "ForgeAgents" then
      key = configured[#configured] or key
    end
    keys[action.command] = key
      :gsub("<leader>", "Leader ")
      :gsub("<C%-S%-([^>]+)>", "Ctrl Shift %1")
      :gsub("<C%-([^>]+)>", "Ctrl %1")
      :gsub("<([^>]+)>", "%1")
  end
  vim.cmd("redrawstatus")
end

function M.get(id)
  if not id then
    return ""
  end
  if id:find("^terminal%-split") then
    id = "terminal"
  end
  return keys[commands[id]] or "q hide"
end

function M.setup()
  M.refresh()
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("ForgePanelHints", { clear = true }),
    pattern = "ForgeShortcutsChanged",
    callback = M.refresh,
  })
end

return M
