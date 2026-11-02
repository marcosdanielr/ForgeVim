-- Event-driven terminal list; hiding it never stops a shell.
local M = {}

function M.refresh(state)
  if not state.tree_buffer or not vim.api.nvim_buf_is_valid(state.tree_buffer) then
    return
  end
  local lines = { "Sessions", "" }
  for index, session in ipairs(state.sessions) do
    local active = index == state.active and "> " or "  "
    local status = session.exit_code ~= nil and "exited" or "running"
    lines[#lines + 1] = active
      .. index
      .. " "
      .. (session.shell or "shell")
      .. " ["
      .. status
      .. "]"
  end
  vim.list_extend(lines, { "", "n new · s split", "Enter select · q hide" })
  require("forge.features.panels.text").write(state.tree_buffer, lines)
end

function M.open(state, focus)
  local windows = require("forge.features.panels.windows")
  local anchor = windows.get("terminal")
  if not anchor or vim.o.columns < 80 or (state.tree_enabled == false and not focus) then
    return
  end
  if not state.tree_buffer or not vim.api.nvim_buf_is_valid(state.tree_buffer) then
    state.tree_buffer = vim.api.nvim_create_buf(false, true)
    vim.bo[state.tree_buffer].bufhidden = "hide"
    vim.bo[state.tree_buffer].filetype = "forge-terminal-tree"
    local options = { buffer = state.tree_buffer, silent = true, nowait = true }
    local function select()
      local index = vim.api.nvim_win_get_cursor(0)[1] - 2
      if state.sessions[index] then
        require("forge.features.terminal").select(index)
      end
    end
    vim.keymap.set("n", "<CR>", select, options)
    vim.keymap.set("n", "<2-LeftMouse>", select, options)
    vim.keymap.set("n", "n", function()
      require("forge.features.terminal").new(false)
    end, options)
    vim.keymap.set("n", "s", function()
      require("forge.features.terminal").new(true)
    end, options)
    vim.keymap.set("n", "q", function()
      state.tree_enabled = false
      windows.hide("terminal-list")
    end, options)
    vim.b[state.tree_buffer].forge_root = state.sessions[1].root
  end
  if focus then
    vim.cmd("stopinsert")
    state.tree_enabled = true
  end
  local window = windows.show("terminal-list", state.tree_buffer, {
    anchor = anchor.window,
    position = "left",
    size = 24,
    focus = focus == true,
    title = "Terminals · " .. require("forge.features.workbench.hints").command("ForgeTerminals"),
  })
  vim.wo[window].wrap = false
  M.refresh(state)
  if focus then
    vim.api.nvim_win_set_cursor(window, { state.active + 2, 0 })
  end
end

return M
