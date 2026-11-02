local M = {}
local namespace = vim.api.nvim_create_namespace("forge-workspace")

function M.render(buffer, root, snapshot)
  if not vim.api.nvim_buf_is_valid(buffer) then
    return
  end
  local window = vim.fn.bufwinid(buffer)
  local width = window > 0 and vim.api.nvim_win_get_width(window) or 80
  local padding = string.rep(" ", math.max(2, math.floor((width - 48) / 2)))
  local lines, highlights, rows = {}, {}, {}
  local function line(text, group)
    lines[#lines + 1] = padding .. text
    highlights[#lines] = group or "ForgeMuted"
  end
  line("")
  line("◇  F O R G E", "ForgeAccent")
  line("Your next idea starts here.", "Normal")
  line("")
  line(vim.fs.basename(root), "Directory")
  line(
    snapshot.branch
      .. "  ·  "
      .. snapshot.changed
      .. " changed paths  ·  "
      .. snapshot.conflicts
      .. " conflicts"
  )
  line("")
  local groups = { "CODE", "SOURCE CONTROL", "WORKSPACE" }
  for index, action in ipairs(require("forge.features.workspace.actions")) do
    if index == 1 or index == 5 or index == 9 then
      line(groups[math.floor((index - 1) / 4) + 1], "ForgeAccent")
    end
    line("  " .. action.key .. "   " .. action.label, "Normal")
    rows[tostring(#lines)] = action.command
    if index % 4 == 0 then
      line("")
    end
  end
  line("Enter opens an action. F1 shows shortcuts.")
  line("Ctrl H/J/K/L  Move between panels")
  line("Leader Leader   Find any command")
  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.bo[buffer].modifiable = false
  vim.b[buffer].forge_workspace_rows = rows
  vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)
  for index, text in ipairs(lines) do
    vim.api.nvim_buf_set_extmark(
      buffer,
      namespace,
      index - 1,
      0,
      { end_col = #text, hl_group = highlights[index] }
    )
  end
  for row = 1, #lines do
    if rows[tostring(row)] then
      return row
    end
  end
end

return M
