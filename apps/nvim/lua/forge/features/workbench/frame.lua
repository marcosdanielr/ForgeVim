local M = {}
local modes = {
  n = "NORMAL",
  i = "INSERT",
  v = "VISUAL",
  V = "V-LINE",
  c = "COMMAND",
  t = "TERMINAL",
  R = "REPLACE",
}
local buffers = {}

local function escape(value)
  return value:gsub("%%", "%%%%")
end

function M.refresh_buffers()
  buffers = {}
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buffer].buflisted and vim.bo[buffer].buftype == "" then
      local path = vim.api.nvim_buf_get_name(buffer)
      buffers[#buffers + 1] =
        { id = buffer, label = path == "" and "Untitled" or vim.fs.basename(path) }
    end
  end
  vim.cmd("redrawstatus")
end

function M.select(buffer, _, button)
  if button == "l" and vim.api.nvim_buf_is_valid(buffer) then
    local editor = require("forge.features.panels.windows").focus_editor()
    vim.api.nvim_win_set_buf(editor, buffer)
  end
end

local function context()
  local window = tonumber(vim.g.statusline_winid) or vim.api.nvim_get_current_win()
  return window, vim.api.nvim_win_get_buf(window)
end

function M.top()
  local window, buffer = context()
  local width = vim.api.nvim_win_get_width(window)
  local title = vim.w[window].forge_panel_title
  if vim.bo[buffer].filetype == "forge-workspace" then
    title = "Welcome to Forge"
  end
  if not title and vim.bo[buffer].filetype == "NvimTree" then
    title = "Explorer"
  end
  if title then
    local text = vim.fn.strcharpart(title, 0, math.max(1, width - 6))
    return "%#ForgeBorder#╭─%#ForgeAccent# "
      .. escape(text)
      .. " %#ForgeBorder#"
      .. string.rep("─", math.max(0, width - vim.fn.strdisplaywidth(text) - 6))
      .. "─╮"
  end
  local tabs, used = {}, 2
  for _, item in ipairs(buffers) do
    local label = " " .. item.label .. (vim.bo[item.id].modified and " ● " or "  ")
    if used + vim.fn.strdisplaywidth(label) > width - 3 then
      break
    end
    tabs[#tabs + 1] = (item.id == buffer and "%#ForgeTabActive#" or "%#ForgeTab#")
      .. "%"
      .. item.id
      .. "@v:lua.require'forge.features.workbench.frame'.select@"
      .. escape(label)
      .. "%T"
    used = used + vim.fn.strdisplaywidth(label)
  end
  if #tabs == 0 then
    tabs[1] = "%#ForgeAccent# Workspace "
    used = used + 11
  end
  return "%#ForgeBorder#╭─"
    .. table.concat(tabs)
    .. "%#ForgeBorder#"
    .. string.rep("─", math.max(0, width - used - 1))
    .. "╮"
end

function M.bottom()
  local window, buffer = context()
  local panel = vim.w[window].forge_panel_title or vim.bo[buffer].buftype ~= ""
  if panel then
    return "%#ForgeBorder#╰─%=%#ForgeBorder#─╯"
  end
  local mode = modes[vim.fn.mode()] or "VISUAL"
  return "%#ForgeBorder#╰─%#ForgeBadge# "
    .. mode
    .. " %#ForgeMuted#  %m%r%=%#ForgeSurface#"
    .. escape(vim.bo[buffer].filetype ~= "" and vim.bo[buffer].filetype or "text")
    .. "  %l:%c  %#ForgeBorder#─╯"
end

function M.apply(window)
  if
    not vim.api.nvim_win_is_valid(window) or vim.api.nvim_win_get_config(window).relative ~= ""
  then
    return
  end
  local buffer = vim.api.nvim_win_get_buf(window)
  if vim.bo[buffer].buftype == "" and vim.w[window].forge_panel_title then
    vim.w[window].forge_panel_title = nil
    vim.wo[window].winhighlight = vim.w[window].forge_previous_highlight or ""
  end
  if vim.w[window].forge_panel_title or vim.bo[buffer].filetype == "NvimTree" then
    if vim.w[window].forge_previous_highlight == nil then
      vim.w[window].forge_previous_highlight = vim.wo[window].winhighlight
    end
    vim.wo[window].winhighlight = "Normal:ForgePanel,NormalNC:ForgePanel,EndOfBuffer:ForgePanel"
  end
  vim.wo[window].winbar = "%!v:lua.require('forge.features.workbench.frame').top()"
  vim.wo[window].statusline = "%!v:lua.require('forge.features.workbench.frame').bottom()"
  vim.wo[window].fillchars =
    "eob: ,vert:│,horiz:─,horizup:┴,horizdown:┬,vertleft:┤,vertright:├,verthoriz:┼"
end

function M.setup()
  local group = vim.api.nvim_create_augroup("ForgeWorkbenchFrame", { clear = true })
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinNew", "WinEnter" }, {
    group = group,
    callback = function()
      M.apply(vim.api.nvim_get_current_win())
    end,
  })
  vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufFilePost", "BufModifiedSet" }, {
    group = group,
    callback = function()
      vim.schedule(M.refresh_buffers)
    end,
  })
  for _, window in ipairs(vim.api.nvim_list_wins()) do
    M.apply(window)
  end
  M.refresh_buffers()
end

return M
