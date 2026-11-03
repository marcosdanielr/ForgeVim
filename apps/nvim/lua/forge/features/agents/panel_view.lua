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

local function matches(entry, previous)
  if not entry or type(previous) ~= "table" then
    return false
  end
  if previous.task then
    return entry.task and entry.task.id == previous.task.id
  end
  return previous.root == entry.root and previous.project == entry.project
    and previous.action == entry.action
end

function M.render(state, message)
  if not vim.api.nvim_buf_is_valid(state.buffer) then
    return
  end
  local window = vim.fn.bufwinid(state.buffer)
  local previous_row = window > 0 and vim.api.nvim_win_get_cursor(window)[1] or 1
  local previous = (vim.b[state.buffer].forge_agent_rows or {})[tostring(previous_row)]
  local width = window > 0 and vim.api.nvim_win_get_width(window) or 36
  local inner = math.max(10, width - 6)
  local lines = { "" }
  local rows, highlights = {}, {}
  local function add(text, entry, group)
    lines[#lines + 1] = text
    rows[tostring(#lines)] = entry
    highlights[#lines] = group
  end
  add("  [n] New agent conversation", { action = "new" })
  add("  [b] Run background task", { action = "background" })
  add("  [a] Add project", { action = "add" })
  add("  [r] Refresh", { action = "refresh" })
  lines[#lines + 1] = ""
  local function card_line(text, entry, group)
    text = vim.fn.strcharpart(text, 0, inner)
    add(
      "  │ " .. text .. string.rep(" ", math.max(0, inner - vim.fn.strdisplaywidth(text))) .. " │",
      entry,
      group
    )
  end
  if message then
    lines[#lines + 1] = "  " .. message
  end
  local current = require("forge.core.project").origin()
  for _, root in ipairs(state.roots or {}) do
    local tasks = state.tasks[root] or {}
    local mark = root == current and "●" or "○"
    add(
      "  " .. mark .. " " .. vim.fs.basename(root) .. "  (" .. #tasks .. ")",
      { root = root, project = true },
      "Title"
    )
    if state.errors and state.errors[root] then
      add("    " .. state.errors[root], { root = root, project = true }, "DiagnosticError")
    elseif #tasks == 0 then
      add("    No agents. n starts one here.", { root = root, project = true }, "ForgeMuted")
    end
    for _, task in ipairs(tasks) do
      local entry = { root = root, task = task }
      local group = groups[task.status] or "Comment"
      add("  ╭" .. string.rep("─", inner + 2) .. "╮", entry, group)
      card_line(task.provider .. " · " .. task.mode .. " · " .. task.status, entry, group)
      card_line(task.prompt:gsub("[\r\n]", " "), entry, "ForgeSurface")
      card_line(task.id, entry, "ForgeMuted")
      add("  ╰" .. string.rep("─", inner + 2) .. "╯", entry, group)
    end
    lines[#lines + 1] = ""
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
  if window > 0 and previous then
    for row = 1, #lines do
      if matches(rows[tostring(row)], previous) then
        vim.api.nvim_win_set_cursor(window, { row, 0 })
        break
      end
    end
  end
end

return M
