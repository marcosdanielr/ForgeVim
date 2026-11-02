local M = {}

function M.enabled(panel)
  local saved = require("forge.core.state").read().startup_panels or {}
  if saved[panel] ~= nil then
    return saved[panel]
  end
  return require("forge.core.config").options.startup_panels[panel]
end

function M.open()
  local windows = require("forge.features.panels.windows")
  local editor = windows.editor()
  if M.enabled("files") and vim.env.FORGE_OFFLINE ~= "1" then
    require("nvim-tree.api").tree.open({
      path = require("forge.core.project").root(),
      focus = false,
    })
  end
  if M.enabled("agents") and vim.o.columns >= 120 then
    require("forge.features.agents.panel").open(false)
  end
  vim.api.nvim_set_current_win(editor)
end

function M.review()
  if require("diffview.lib").get_current_view() then
    vim.cmd("DiffviewClose")
  else
    require("forge.features.git").diff()
  end
end

function M.debug()
  require("dapui").toggle()
end

function M.logs()
  if require("forge.features.panels.windows").hide("logs") then
    return
  end
  require("forge.features.agents.panel").open(true)
  vim.notify("Select an agent, then press L to open its logs")
end

return M
