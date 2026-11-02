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
  local width = window > 0 and vim.api.nvim_win_get_width(window) or 36
  local inner = math.max(10, width - 6)
  local lines = { "", "  [n] New task", "  [c] New CLI chat", "  [r] Refresh", "" }
  local rows, highlights = {}, {}
  local function card_line(text, task, group)
    text = vim.fn.strcharpart(text, 0, inner)
    lines[#lines + 1] = "  │ "
      .. text
      .. string.rep(" ", math.max(0, inner - vim.fn.strdisplaywidth(text)))
      .. " │"
    rows[tostring(#lines)] = task
    highlights[#lines] = group
  end
  if message then
    lines[#lines + 1] = "  " .. message
  elseif #state.tasks == 0 then
    lines[#lines + 1] = "  No agents yet."
    lines[#lines + 1] = ""
    lines[#lines + 1] = "  Start a task"
    lines[#lines + 1] = "  or CLI chat."
    lines[#lines + 1] = ""
    lines[#lines + 1] = "  Review changes"
    lines[#lines + 1] = "  before applying."
  else
    for _, task in ipairs(state.tasks) do
      local group = groups[task.status] or "Comment"
      lines[#lines + 1] = "  ╭" .. string.rep("─", inner + 2) .. "╮"
      highlights[#lines] = group
      card_line(task.provider .. " · " .. task.status, task, group)
      card_line(task.prompt:gsub("[\r\n]", " "), task, "ForgeSurface")
      card_line(task.id, task, "ForgeMuted")
      lines[#lines + 1] = "  ╰" .. string.rep("─", inner + 2) .. "╯"
      highlights[#lines] = group
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
