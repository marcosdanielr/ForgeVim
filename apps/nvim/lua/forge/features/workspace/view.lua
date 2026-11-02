local M = {}
local namespace = vim.api.nvim_create_namespace("forge-workspace")

function M.render(buffer, root, snapshot)
  if not vim.api.nvim_buf_is_valid(buffer) then
    return
  end
  local window = vim.fn.bufwinid(buffer)
  local width = window > 0 and vim.api.nvim_win_get_width(window) or 80
  local compact = window > 0 and vim.api.nvim_win_get_height(window) < 38
  local padding = string.rep(" ", math.max(2, math.floor((width - 66) / 2)))
  local lines, highlights, rows = {}, {}, {}
  local function line(text, group)
    lines[#lines + 1] = padding .. text
    highlights[#lines] = group or "Comment"
  end
  line("")
  if compact then
    line("F O R G E  /  NEOVIM WORKSPACE", "Title")
  else
    line(
      "███████╗ ██████╗ ██████╗  ██████╗ ███████╗",
      "Title"
    )
    line(
      "██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝",
      "Title"
    )
    line(
      "█████╗  ██║   ██║██████╔╝██║  ███╗█████╗",
      "Title"
    )
    line(
      "██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝",
      "Title"
    )
    line(
      "██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗",
      "Title"
    )
    line(
      "╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝",
      "Title"
    )
  end
  line("")
  line("Your code. Your agents. Your decision.", "Normal")
  line("")
  line(vim.fs.basename(root) .. "  /  " .. snapshot.branch, "Directory")
  line(string.format("%d changed paths    %d conflicts", snapshot.changed, snapshot.conflicts))
  line("")
  local groups = { "CODE & REVIEW", "GIT & AGENTS", "MAKE IT YOURS" }
  for index, action in ipairs(require("forge.features.workspace.actions")) do
    if index == 1 or index == 5 or index == 9 then
      if not compact then
        line("")
      end
      line(groups[math.floor((index - 1) / 4) + 1], "Special")
      if not compact then
        line("")
      end
    end
    line("[" .. action.key .. "]  " .. action.label, "Function")
    rows[#lines] = action.command
  end
  line("")
  line("Enter opens the selected action. Or press its letter.")
  line("Space Space  All commands    Ctrl B  Files    R  Refresh")
  line("Ctrl H / J / K / L  Focus panels    h / j / k / l  Move cursor")
  line("")
  line("Review any author's changes. You decide what gets committed.", "NonText")
  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.bo[buffer].modifiable = false
  vim.b[buffer].forge_workspace_rows = rows
  vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)
  for index, text in ipairs(lines) do
    vim.api.nvim_buf_set_extmark(buffer, namespace, index - 1, 0, {
      end_col = #text,
      hl_group = highlights[index],
    })
  end
  for row = 1, #lines do
    if rows[row] then
      return row
    end
  end
end

return M
