-- Native splits own presentation only. Hiding a panel never deletes its buffer or job.
local M = {}
local tabs = {}

function M.state(tab)
  tab = tab or vim.api.nvim_get_current_tabpage()
  tabs[tab] = tabs[tab] or { panels = {} }
  return tabs[tab]
end

function M.editor()
  local state = M.state()
  local current = vim.api.nvim_get_current_win()
  local function eligible(window)
    if not window or not vim.api.nvim_win_is_valid(window) then
      return false
    end
    local buffer = vim.api.nvim_win_get_buf(window)
    return vim.api.nvim_win_get_tabpage(window) == vim.api.nvim_get_current_tabpage()
      and (vim.bo[buffer].buftype == "" or vim.bo[buffer].filetype == "forge-workspace")
      and vim.api.nvim_win_get_config(window).relative == ""
  end
  if eligible(current) then
    state.editor = current
  end
  if eligible(state.editor) then
    return state.editor
  end
  for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if eligible(window) then
      state.editor = window
      return window
    end
  end
  vim.cmd("rightbelow new")
  state.editor = vim.api.nvim_get_current_win()
  return state.editor
end

function M.focus_editor()
  local window = M.editor()
  vim.api.nvim_set_current_win(window)
  return window
end

function M.get(id, tab)
  local panel = M.state(tab).panels[id]
  if
    panel
    and panel.window
    and vim.api.nvim_win_is_valid(panel.window)
    and vim.api.nvim_win_get_buf(panel.window) == panel.buffer
  then
    return panel
  end
end

function M.hide(id, tab)
  local panel = M.get(id, tab)
  if not panel then
    return false
  end
  if #vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(panel.window)) == 1 then
    M.focus_editor()
  end
  vim.api.nvim_win_hide(panel.window)
  if panel.window == nil then
    return true
  end
  panel.window = nil
  if panel.on_hide then
    panel.on_hide()
  end
  return true
end

function M.show(id, buffer, options)
  options = options or {}
  local state = M.state()
  local visible = M.get(id)
  if visible then
    vim.api.nvim_win_set_buf(visible.window, buffer)
    visible.buffer = buffer
    visible.on_hide = options.on_hide
    vim.wo[visible.window].winbar = "  " .. (options.title or id):gsub("%%", "%%%%")
    if options.focus ~= false then
      vim.api.nvim_set_current_win(visible.window)
    end
    return visible.window
  end
  local anchor = options.anchor or M.editor()
  local configuration = { split = options.position or "right", win = anchor }
  if configuration.split == "above" or configuration.split == "below" then
    configuration.height = math.max(5, math.min(options.size or 12, math.floor(vim.o.lines / 2)))
  else
    configuration.width = math.max(24, math.min(options.size or 38, math.floor(vim.o.columns / 3)))
  end
  local window = vim.api.nvim_open_win(buffer, options.focus ~= false, configuration)
  state.panels[id] = { window = window, buffer = buffer, on_hide = options.on_hide }
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(window),
    once = true,
    callback = function()
      local panel = state.panels[id]
      if panel and panel.window == window then
        panel.window = nil
        if panel.on_hide then
          panel.on_hide()
        end
      end
    end,
  })
  vim.wo[window].number = false
  vim.wo[window].relativenumber = false
  vim.wo[window].signcolumn = "no"
  vim.wo[window].winbar = "  " .. (options.title or id):gsub("%%", "%%%%")
  vim.wo[window].winfixwidth = configuration.width ~= nil
  vim.wo[window].winfixheight = configuration.height ~= nil
  return window
end

return M
