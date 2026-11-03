local M = {}

M.choices = {
  { key = "1", title = "LEFT", position = "left", hint = "Place panel beside editor" },
  { key = "2", title = "RIGHT", position = "right", hint = "Place panel beside editor" },
  { key = "3", title = "BELOW", position = "below", hint = "Place panel under editor" },
  { key = "4", title = "ABOVE", position = "above", hint = "Place panel over editor" },
}

local function close(windows)
  for _, window in ipairs(windows) do
    if vim.api.nvim_win_is_valid(window) then
      vim.api.nvim_win_close(window, true)
    end
  end
end

local function zone(choice, width, height)
  local side_width = math.max(20, math.floor(width * 0.28))
  local band_width = math.max(28, math.floor(width * 0.46))
  local side_height = math.max(8, math.floor(height * 0.58))
  local band_height = math.max(5, math.floor(height * 0.24))
  if choice.position == "left" then
    return {
      row = math.floor((height - side_height) / 2),
      col = 1,
      width = side_width,
      height = side_height,
    }
  end
  if choice.position == "right" then
    return {
      row = math.floor((height - side_height) / 2),
      col = width - side_width - 1,
      width = side_width,
      height = side_height,
    }
  end
  if choice.position == "above" then
    return {
      row = 1,
      col = math.floor((width - band_width) / 2),
      width = band_width,
      height = band_height,
    }
  end
  return {
    row = height - band_height - 1,
    col = math.floor((width - band_width) / 2),
    width = band_width,
    height = band_height,
  }
end

local function buffer(choice)
  local value = vim.api.nvim_create_buf(false, true)
  vim.bo[value].bufhidden = "wipe"
  vim.bo[value].filetype = "forge-panel-move"
  vim.api.nvim_buf_set_lines(value, 0, -1, false, {
    "",
    "          " .. choice.key,
    "",
    "      " .. choice.title,
    "",
    "  " .. choice.hint,
  })
  vim.api.nvim_buf_add_highlight(value, -1, "ForgeMoveKey", 1, 0, -1)
  vim.api.nvim_buf_add_highlight(value, -1, "ForgeAccent", 3, 0, -1)
  return value
end

local function open_picker(id, title)
  -- The picker must not shrink with its source panel. Once a panel moves to a
  -- side, its editor window can be too narrow for a useful four-zone layout.
  -- The global editor surface keeps the same visual picker on every invocation.
  local width = vim.o.columns
  local height = vim.o.lines - vim.o.cmdheight
  local windows = {}
  local function select(choice)
    close(windows)
    local moved, error = require("forge.features.panels.windows").move_window(id, choice.position)
    if not moved then
      vim.notify(error or "Could not move this window", vim.log.levels.WARN)
    end
  end
  for _, choice in ipairs(M.choices) do
    local area = zone(choice, width, height)
    local value = buffer(choice)
    local window = vim.api.nvim_open_win(value, false, {
      relative = "editor",
      row = area.row,
      col = area.col,
      width = area.width,
      height = area.height,
      style = "minimal",
      border = "rounded",
      title = " " .. choice.key .. " ",
      title_pos = "center",
      zindex = 70,
    })
    vim.wo[window].winhl = "Normal:ForgeMoveZone,FloatBorder:ForgeAccent"
    vim.wo[window].wrap = false
    vim.wo[window].cursorline = false
    windows[#windows + 1] = window
    vim.keymap.set("n", choice.key, function()
      select(choice)
    end, { buffer = value, desc = "Move panel " .. choice.title:lower() })
    vim.keymap.set("n", "<LeftMouse>", function()
      select(choice)
    end, { buffer = value, desc = "Move panel " .. choice.title:lower() })
    vim.keymap.set("n", "<Esc>", function()
      close(windows)
    end, { buffer = value, desc = "Cancel panel move" })
  end
  local prompt = vim.api.nvim_create_buf(false, true)
  vim.bo[prompt].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(prompt, 0, -1, false, {
    "Move " .. title,
    "1 Left  ·  2 Right  ·  3 Below  ·  4 Above",
    "Click a zone or press its number  ·  Esc cancel",
  })
  local prompt_width = math.min(width - 8, 54)
  local prompt_window = vim.api.nvim_open_win(prompt, true, {
    relative = "editor",
    row = math.floor((height - 5) / 2),
    col = math.floor((width - prompt_width) / 2),
    width = prompt_width,
    height = 3,
    style = "minimal",
    border = "rounded",
    title = " PANEL POSITION ",
    title_pos = "center",
    zindex = 80,
  })
  vim.wo[prompt_window].winhl = "Normal:ForgeSurface,FloatBorder:ForgeMoveKey"
  windows[#windows + 1] = prompt_window
  for _, choice in ipairs(M.choices) do
    vim.keymap.set("n", choice.key, function()
      select(choice)
    end, { buffer = prompt, desc = "Move panel " .. choice.title:lower() })
  end
  vim.keymap.set("n", "h", function()
    select(M.choices[1])
  end, { buffer = prompt, desc = "Move panel left" })
  vim.keymap.set("n", "l", function()
    select(M.choices[2])
  end, { buffer = prompt, desc = "Move panel right" })
  vim.keymap.set("n", "j", function()
    select(M.choices[3])
  end, { buffer = prompt, desc = "Move panel below" })
  vim.keymap.set("n", "k", function()
    select(M.choices[4])
  end, { buffer = prompt, desc = "Move panel above" })
  for _, key in ipairs({ "<Esc>", "q" }) do
    vim.keymap.set("n", key, function()
      close(windows)
    end, { buffer = prompt, desc = "Cancel panel move" })
  end
end

function M.choose()
  local window = vim.api.nvim_get_current_win()
  local buffer = vim.api.nvim_win_get_buf(window)
  local title = vim.w[window].forge_panel_title
    or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buffer), ":t")
    or vim.bo[buffer].filetype
  open_picker(window, title ~= "" and title or "window")
end

return M
