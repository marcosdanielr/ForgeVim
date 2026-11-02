-- Real native windows: prove composition and startup remain side-effect free.
return function(source)
  local windows = require("forge.features.panels.windows")
  vim.o.columns, vim.o.lines = 190, 58
  local before = vim.api.nvim_get_current_buf()
  require("forge.features.layout").open()
  assert(vim.api.nvim_get_current_buf() == before, "Layout replaced source buffer")
  for _, id in ipairs({ "activity", "agents", "chat", "terminal", "logs" }) do
    local panel = assert(windows.get(id), "Missing workbench panel: " .. id)
    assert(vim.bo[panel.buffer].buftype ~= "terminal", "Startup launched a process")
    assert(vim.wo[panel.window].winbar:find("workbench.frame", 1, true), "Missing panel frame")
  end
  local chat = windows.get("chat")
  local navigation = windows.get("activity")
  local editor = windows.editor()
  local function column(window)
    return vim.api.nvim_win_get_position(window)[2]
  end
  assert(
    column(navigation.window) < column(editor) and column(editor) < column(chat.window),
    "Pane order is wrong"
  )
  vim.api.nvim_set_current_win(chat.window)
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  vim.fn.maparg("<2-LeftMouse>", "n", false, true).callback()
  assert(vim.api.nvim_get_current_buf() == chat.buffer, "Chat heading started a provider")
  require("forge.features.agents.chat").toggle()
  assert(not windows.get("chat"), "Chat placeholder did not hide")
  require("forge.features.agents.chat").toggle()
  assert(vim.bo.filetype == "forge-chat-welcome", "Chat toggle started a provider")
  local tree_action
  for _, action in ipairs(require("forge.core.actions")) do
    if action.command == "ForgeTree" then
      tree_action = action
    end
  end
  require("forge.features.shortcuts").save(tree_action, { "<F8>" })
  assert(
    table
      .concat(vim.api.nvim_buf_get_lines(navigation.buffer, 0, -1, false), "\n")
      :find("F8", 1, true),
    "Navigation hints ignored custom keys"
  )
  require("forge.features.shortcuts").save(tree_action, nil)
  require("forge.features.workbench.activity").toggle()
  assert(not windows.get("activity"), "Navigation did not hide")
  assert(not vim.api.nvim_buf_is_valid(navigation.buffer), "Stateless navigation buffer leaked")
  require("forge.features.workbench.activity").toggle()
  local restored = assert(windows.get("activity"))
  assert(
    column(restored.window) == column(windows.get("agents").window),
    "Restoring navigation created a duplicate sidebar"
  )
  require("forge.features.workbench.activity").toggle()
  windows.focus_editor()
  vim.api.nvim_win_set_buf(editor, source)
  require("forge.features.workbench.frame").refresh_buffers()
  local rendered = vim.api.nvim_eval_statusline(
    require("forge.features.workbench.frame").top(),
    { winid = editor }
  )
  assert(rendered.str:find("sample.txt", 1, true), "Source buffer tab missing")
  for _, id in ipairs({ "agents", "chat", "terminal", "logs" }) do
    windows.hide(id)
  end
  windows.focus_editor()
  assert(vim.v.errmsg == "", "Workbench render error: " .. vim.v.errmsg)
end
