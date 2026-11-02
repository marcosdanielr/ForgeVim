local M = {}
local symbols = {
  ["Agents"] = "",
  ["Explorer"] = "",
  ["Search"] = "",
  ["Source control"] = "",
  ["Debug"] = "",
  ["Problems"] = "",
  ["Terminal"] = "",
  ["Settings"] = "",
}
local entries = {
  { "Agents", "ForgeAgents" },
  { "Explorer", "ForgeTree" },
  { "Search", "ForgeSearch" },
  { "Source control", "ForgeGit" },
  { "Debug", "ForgePanelDebug" },
  { "Problems", "ForgeProblems" },
  { "Terminal", "ForgeTerminal" },
  { "Settings", "ForgeSettings" },
}

local function shortcut(command)
  for _, action in ipairs(require("forge.core.actions")) do
    if action.command == command then
      local key = require("forge.features.shortcuts").keys(action)[1] or "Unbound"
      return key
        :gsub("<leader>", "Leader ")
        :gsub("<C%-S%-([^>]+)>", "Ctrl Shift %1")
        :gsub("<C%-([^>]+)>", "Ctrl %1")
        :gsub("<([^>]+)>", "%1")
    end
  end
  return ""
end

function M.render(buffer)
  local text = require("forge.features.panels.text")
  local lines, rows = { "", "  YOUR WORKSPACE", "" }, {}
  for _, entry in ipairs(entries) do
    lines[#lines + 1] = "  "
      .. require("forge.features.workbench.icons").symbol(symbols[entry[1]] .. " ")
      .. entry[1]
    rows[tostring(#lines)] = entry[2]
    lines[#lines + 1] = "  " .. shortcut(entry[2])
    rows[tostring(#lines)] = entry[2]
    lines[#lines + 1] = ""
  end
  lines[#lines + 1] = "  " .. shortcut("ForgeHelp") .. "   Help"
  rows[tostring(#lines)] = "ForgeHelp"
  text.write(buffer, lines)
  vim.b[buffer].forge_navigation_rows = rows
  local namespace = vim.api.nvim_create_namespace("forge-navigation")
  vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)
  for row = 1, #lines do
    vim.api.nvim_buf_set_extmark(buffer, namespace, row - 1, 0, {
      end_col = #lines[row],
      hl_group = row % 3 == 1 and "ForgeAccent" or "ForgeMuted",
    })
  end
end

function M.open(anchor)
  local windows = require("forge.features.panels.windows")
  if windows.get("activity") then
    return
  end
  local text = require("forge.features.panels.text")
  local buffer = text.create("Navigation", require("forge.core.project").root(), "forge-navigation")
  vim.bo[buffer].bufhidden = "wipe"
  M.render(buffer)
  for _, key in ipairs({ "<CR>", "<2-LeftMouse>" }) do
    vim.keymap.set("n", key, function()
      local command =
        vim.b[buffer].forge_navigation_rows[tostring(vim.api.nvim_win_get_cursor(0)[1])]
      if command then
        vim.cmd(command)
      end
    end, { buffer = buffer, desc = "Open workspace section" })
  end
  vim.keymap.set("n", "q", function()
    windows.hide("activity")
  end, { buffer = buffer, desc = "Hide navigation" })
  windows.show(
    "activity",
    buffer,
    { title = "Menu", position = "left", anchor = anchor, size = 22, focus = false }
  )
  if windows.get("agents") then
    M.reanchor(anchor)
  end
end

function M.reanchor(tree)
  local windows = require("forge.features.panels.windows")
  local navigation = windows.get("activity")
  if not navigation then
    return
  end
  vim.fn.win_splitmove(navigation.window, tree, { vertical = true, rightbelow = false })
  vim.api.nvim_win_set_width(navigation.window, 22)
  local agents = windows.get("agents")
  if agents then
    vim.fn.win_splitmove(agents.window, navigation.window, { vertical = false, rightbelow = true })
    vim.api.nvim_win_set_height(agents.window, 18)
  end
end

function M.toggle()
  local windows = require("forge.features.panels.windows")
  if not windows.hide("activity") then
    local anchor = windows.editor()
    for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.bo[vim.api.nvim_win_get_buf(window)].filetype == "NvimTree" then
        anchor = window
      end
    end
    M.open(anchor)
  end
end

vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("ForgeNavigationHints", { clear = true }),
  pattern = "ForgeShortcutsChanged",
  callback = function()
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buffer].filetype == "forge-navigation" then
        M.render(buffer)
      end
    end
  end,
})

return M
