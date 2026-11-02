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
  local resize = require("forge.features.panels.resize")
  local navigation_window = windows.get("activity").window
  vim.api.nvim_set_current_win(navigation_window)
  local width = vim.api.nvim_win_get_width(0)
  resize.width(3)
  assert(vim.api.nvim_win_get_width(0) == width + 3, "Window did not widen")
  resize.width(-3)
  assert(vim.api.nvim_win_get_width(0) == width, "Window width did not restore")
  local height = vim.api.nvim_win_get_height(0)
  resize.height(2)
  assert(vim.api.nvim_win_get_height(0) == height + 2, "Window did not grow taller")
  resize.height(-2)
  assert(vim.api.nvim_win_get_height(0) == height, "Window height did not restore")
  assert(
    vim.fn.maparg("<C-S-Right>", "t"):find("ForgeWindowWider", 1, true),
    "Terminal resize mapping missing"
  )
  assert(vim.fn.maparg("<Tab>", "t") == "", "Buffer aliases intercepted shell Tab completion")
  assert(vim.fn.maparg("<S-Tab>", "t") == "", "Buffer aliases intercepted shell Shift Tab")
  assert(
    vim.fn.maparg("<Tab>", "n", false, true).desc == "Next buffer / terminal",
    "VIMarcos Tab alias missing"
  )
  assert(
    vim.fn.maparg("<S-Tab>", "n", false, true).desc == "Previous buffer / terminal",
    "VIMarcos Shift Tab alias missing"
  )
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
  assert(
    require("forge.features.workbench.hints").get("files") == "F8",
    "Panel header ignored customized hide shortcut"
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
  local diagnostics_config = vim.diagnostic.config()
  assert(type(diagnostics_config.virtual_text) == "table", "Inline diagnostic messages disabled")
  assert(diagnostics_config.underline, "Diagnostic underlines disabled")
  assert(vim.o.laststatus == 3, "Global bottom statusbar missing")
  local config = require("forge.core.config").options
  local original_icons, original_branch = config.nerd_fonts, vim.t.forge_chrome_branch
  config.nerd_fonts = false
  vim.t.forge_chrome_branch = "feature/ui...origin/feature/ui"
  vim.bo[source].filetype = "lua"
  local diagnostics = vim.api.nvim_create_namespace("forge-statusline-test")
  vim.diagnostic.set(diagnostics, source, {
    { lnum = 0, col = 0, message = "fixture error", severity = vim.diagnostic.severity.ERROR },
    { lnum = 0, col = 0, message = "fixture warning", severity = vim.diagnostic.severity.WARN },
  })
  assert(
    vim.wait(1000, function()
      return require("forge.features.workbench.statusline").render():find("E 1", 1, true)
    end),
    "Diagnostic statusbar did not update"
  )
  local status =
    vim.api.nvim_eval_statusline(require("forge.features.workbench.statusline").render(), {}).str
  for _, value in ipairs({
    "NORMAL",
    "feature/ui",
    "E 1",
    "W 1",
    "lua",
    "UTF-8",
    "LF",
    "Ln 1, Col 1",
  }) do
    assert(status:find(value, 1, true), "Missing statusbar metadata: " .. value)
  end
  assert(not status:find("origin/", 1, true), "Tracking branch leaked into statusbar")
  vim.diagnostic.reset(diagnostics, source)
  config.nerd_fonts, vim.t.forge_chrome_branch = original_icons, original_branch
  for _, id in ipairs({ "agents", "chat", "terminal", "logs" }) do
    windows.hide(id)
  end
  windows.focus_editor()
  assert(vim.v.errmsg == "", "Workbench render error: " .. vim.v.errmsg)
end
