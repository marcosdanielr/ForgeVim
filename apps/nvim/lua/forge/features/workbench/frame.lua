local M = {}
local buffers = {}

local function escape(value)
  return value:gsub("%%", "%%%%")
end

local function tab_label(item, active)
  local group = active and "%#ForgeTabActive#" or "%#ForgeTab#"
  local suffix = vim.bo[item.id].modified and " ● " or "  "
  local prefix = item.icon ~= "" and item.icon .. " " or ""
  local styled = group .. " "
  if item.icon ~= "" then
    styled = styled .. "%#" .. item.highlight .. "#" .. prefix .. group
  end
  return " " .. prefix .. item.label .. suffix, styled .. escape(item.label) .. suffix
end

function M.refresh_buffers()
  buffers = {}
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buffer].buflisted and vim.bo[buffer].buftype == "" then
      local path = vim.api.nvim_buf_get_name(buffer)
      local icon, highlight = require("forge.features.workbench.icons").file(buffer)
      buffers[#buffers + 1] = {
        id = buffer,
        label = path == "" and "Untitled" or vim.fs.basename(path),
        icon = icon,
        highlight = highlight,
      }
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
  if vim.bo[buffer].filetype == "grug-far" then
    return require("forge.features.search.preview").header(window, width)
  end
  local title = vim.w[window].forge_panel_title
  if vim.bo[buffer].filetype == "forge-workspace" then
    title = "Welcome to Forge"
  end
  if not title and vim.bo[buffer].filetype == "NvimTree" then
    title = "Explorer"
  end
  if
    title
    and vim.w[window].forge_panel_id
    and vim.w[window].forge_panel_id:find("^terminal")
    and vim.bo[buffer].buftype == "terminal"
  then
    return require("forge.features.terminal.toolbar").render(window, title, width)
  end
  if title then
    local id = vim.bo[buffer].filetype == "NvimTree" and "files" or vim.w[window].forge_panel_id
    local hint = require("forge.features.workbench.hints").get(id)
    local available = math.max(1, width - 6)
    local base = title:match("^(.-)%s+/") or title
    local text = vim.fn.strcharpart(
      base,
      0,
      math.max(1, available - (hint ~= "" and vim.fn.strdisplaywidth(hint) + 1 or 0))
    )
    if hint ~= "" then
      text = text .. " " .. hint
    end
    return "%#ForgeBorder#╭─%#ForgeAccent# "
      .. escape(text)
      .. " %#ForgeBorder#"
      .. string.rep("─", math.max(0, width - vim.fn.strdisplaywidth(text) - 6))
      .. "─╮"
  end
  local tabs, used = {}, 2
  for _, item in ipairs(buffers) do
    local label, styled = tab_label(item, item.id == buffer)
    if used + vim.fn.strdisplaywidth(label) > width - 3 then
      break
    end
    tabs[#tabs + 1] = "%"
      .. item.id
      .. "@v:lua.require'forge.features.workbench.frame'.select@"
      .. styled
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

function M.apply(window)
  if
    not vim.api.nvim_win_is_valid(window) or vim.api.nvim_win_get_config(window).relative ~= ""
  then
    return
  end
  local buffer = vim.api.nvim_win_get_buf(window)
  if vim.bo[buffer].buftype == "" and vim.w[window].forge_panel_title then
    vim.w[window].forge_panel_title = nil
    vim.w[window].forge_panel_id = nil
    vim.wo[window].winhighlight = vim.w[window].forge_previous_highlight or ""
  end
  if vim.w[window].forge_panel_title or vim.bo[buffer].filetype == "NvimTree" then
    if vim.w[window].forge_previous_highlight == nil then
      vim.w[window].forge_previous_highlight = vim.wo[window].winhighlight
    end
    vim.wo[window].winhighlight = "Normal:ForgePanel,NormalNC:ForgePanel,EndOfBuffer:ForgePanel"
  end
  vim.wo[window].winbar = "%!v:lua.require('forge.features.workbench.frame').top()"
  vim.wo[window].statusline = "%!v:lua.require('forge.features.workbench.statusline').render()"
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
  vim.api.nvim_create_autocmd(
    { "BufAdd", "BufDelete", "BufFilePost", "BufModifiedSet", "FileType" },
    {
      group = group,
      callback = function()
        vim.schedule(M.refresh_buffers)
      end,
    }
  )
  for _, window in ipairs(vim.api.nvim_list_wins()) do
    M.apply(window)
  end
  M.refresh_buffers()
end

return M
