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
  -- BR-ED-19: startup panes contain no processes; smaller terminals keep editing space.
  local empty = require("forge.features.workbench.empty")
  if M.enabled("navigation") and vim.o.columns >= 150 then
    local tree
    for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.bo[vim.api.nvim_win_get_buf(window)].filetype == "NvimTree" then
        tree = window
      end
    end
    require("forge.features.workbench.activity").open(tree or editor)
  end
  if M.enabled("chat") and vim.o.columns >= 120 then
    empty.open("chat", { position = "right", anchor = editor, size = 40 })
  end
  if M.enabled("agents") and vim.o.columns >= 120 then
    require("forge.features.agents.panel").open(false)
  end
  if M.enabled("output") and vim.o.columns >= 150 and vim.o.lines >= 40 then
    local terminal = empty.open("terminal", { position = "below", anchor = editor, size = 10 })
    if terminal then
      empty.open("logs", { position = "left", anchor = terminal, size = 30 })
    end
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
  local windows = require("forge.features.panels.windows")
  local previous = windows.state().panels.logs
  if previous and vim.api.nvim_buf_is_valid(previous.buffer) then
    windows.show("logs", previous.buffer, { position = "below", title = "Agent logs" })
  else
    require("forge.features.workbench.empty").open(
      "logs",
      { position = "below", size = 10, focus = true }
    )
  end
end

return M
