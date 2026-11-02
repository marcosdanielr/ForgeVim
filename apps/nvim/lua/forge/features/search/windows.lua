local M = {}

local function create(name, config, editable)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].filetype = "forge-replace-" .. name
  vim.bo[buffer].modifiable = editable == true
  local window = vim.api.nvim_open_win(
    buffer,
    false,
    vim.tbl_extend("force", {
      relative = "editor",
      style = "minimal",
      border = "rounded",
      zindex = 60,
    }, config)
  )
  vim.wo[window].winhighlight = "Normal:NormalFloat,FloatBorder:TelescopeBorder"
  vim.wo[window].wrap = false
  return { buffer = buffer, window = window }
end

function M.open()
  if vim.o.columns < 58 or vim.o.lines < 25 then
    vim.notify("Find and replace needs at least 58 columns and 25 rows", vim.log.levels.WARN)
    return
  end
  local width, height = math.min(126, vim.o.columns - 6), math.min(32, vim.o.lines - 6)
  local row, col =
    math.floor((vim.o.lines - height - 2) / 2), math.floor((vim.o.columns - width - 2) / 2)
  local windows = { origin = vim.api.nvim_get_current_win(), width = width }
  windows.frame = create("frame", {
    row = row,
    col = col,
    width = width,
    height = height,
    title = " Find and replace ",
    title_pos = "center",
    footer = " Tab next field · Esc normal / close ",
    footer_pos = "center",
  })
  vim.api.nvim_win_set_config(windows.frame.window, { zindex = 50 })
  local function pane(name, y, x, w, h, title, editable)
    windows[name] = create(name, {
      row = row + y,
      col = col + x,
      width = w,
      height = h,
      title = title and (" " .. title .. " ") or nil,
    }, editable)
  end
  pane("search", 1, 2, width - 4, 1, "Find", true)
  pane("replacement", 4, 2, width - 4, 1, "Replace with · empty removes the match", true)
  pane("options", 7, 2, width - 4, 1, "Search options · click or Enter")
  local content = height - 16
  if width >= 96 then
    local left = math.floor((width - 7) / 2)
    pane("results", 10, 2, left, content, "Matches · arrows / j k")
    pane(
      "preview",
      10,
      left + 5,
      width - left - 7,
      content,
      "Selected occurrence · before / after"
    )
  else
    local list = math.max(1, content - 4)
    pane("results", 10, 2, width - 4, list, "Matches · arrows / j k")
    pane("preview", 12 + list, 2, width - 4, 2, "Before / after")
  end
  pane("actions", height - 3, 2, width - 4, 2, "Actions · click or Enter")
  return windows
end

function M.write(pane, lines)
  if not vim.api.nvim_buf_is_valid(pane.buffer) then
    return
  end
  vim.bo[pane.buffer].modifiable = true
  vim.api.nvim_buf_set_lines(pane.buffer, 0, -1, false, lines)
  vim.bo[pane.buffer].modifiable = false
end

function M.close(windows)
  for _, name in ipairs({
    "search",
    "replacement",
    "options",
    "results",
    "preview",
    "actions",
    "frame",
  }) do
    local pane = windows[name]
    if vim.api.nvim_win_is_valid(pane.window) then
      vim.api.nvim_win_close(pane.window, true)
    end
  end
  if vim.api.nvim_win_is_valid(windows.origin) then
    vim.api.nvim_set_current_win(windows.origin)
  end
end

return M
