local M = {}
local namespace = vim.api.nvim_create_namespace("forge-agents")
local groups = {
  running = "DiagnosticOk",
  queued = "DiagnosticInfo",
  ready = "Function",
  reviewing = "Function",
  failed = "DiagnosticError",
  interrupted = "DiagnosticWarn",
}

function M.render(state, message)
  if not vim.api.nvim_buf_is_valid(state.buffer) then
    return
  end
  local window = vim.fn.bufwinid(state.buffer)
  local previous_row = window > 0 and vim.api.nvim_win_get_cursor(window)[1] or 1
  local previous = (vim.b[state.buffer].forge_agent_rows or {})[tostring(previous_row)]
  local lines =
    { "", "  AGENTS", "", "  [n] New task    [c] CLI chat", "  [r] Refresh    [Enter] Actions", "" }
  local rows, highlights = {}, {}
  if message then
    lines[#lines + 1] = "  " .. message
  elseif #state.tasks == 0 then
    lines[#lines + 1] = "  No tasks in this project."
    lines[#lines + 1] = "  Start a task or open a CLI chat."
  else
    for _, task in ipairs(state.tasks) do
      lines[#lines + 1] = "  " .. task.provider .. "  [" .. task.status .. "]"
      highlights[#lines] = groups[task.status] or "Comment"
      rows[tostring(#lines)] = task
      lines[#lines + 1] = "  " .. task.prompt:gsub("[\r\n]", " "):sub(1, 80)
      rows[tostring(#lines)] = task
      lines[#lines + 1] = "  " .. task.id
      rows[tostring(#lines)] = task
      lines[#lines + 1] = ""
    end
  end
  require("forge.features.panels.text").write(state.buffer, lines)
  vim.api.nvim_buf_clear_namespace(state.buffer, namespace, 0, -1)
  for row, group in pairs(highlights) do
    vim.api.nvim_buf_set_extmark(
      state.buffer,
      namespace,
      row - 1,
      0,
      { end_col = #lines[row], hl_group = group }
    )
  end
  vim.b[state.buffer].forge_agent_rows = rows
  if window > 0 and type(previous) == "table" then
    for row = 1, #lines do
      if rows[tostring(row)] and rows[tostring(row)].id == previous.id then
        vim.api.nvim_win_set_cursor(window, { row, 0 })
        break
      end
    end
  end
end

return M
