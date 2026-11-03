-- Centered modal prompt for short text. Enter confirms; Esc, q (normal), or focus loss cancels.
local M = {}

function M.open(options, callback)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].swapfile = false
  vim.bo[buffer].filetype = "forge-input"
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { options.default or "" })
  local width = math.max(30, math.min(64, vim.o.columns - 8))
  local window = vim.api.nvim_open_win(buffer, true, {
    relative = "editor",
    row = math.max(1, math.floor((vim.o.lines - 3) / 3)),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = 1,
    style = "minimal",
    border = "rounded",
    title = " " .. (options.prompt or "Input") .. " ",
    title_pos = "center",
    footer = " Enter confirm  ·  Esc cancel ",
    footer_pos = "center",
  })
  vim.wo[window].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"
  local finished = false
  local function finish(value)
    if finished then
      return
    end
    finished = true
    vim.cmd("stopinsert")
    if vim.api.nvim_win_is_valid(window) then
      vim.api.nvim_win_close(window, true)
    end
    if value and value:match("%S") then
      callback(vim.trim(value))
    end
  end
  local function confirm()
    finish(vim.api.nvim_buf_get_lines(buffer, 0, 1, false)[1])
  end
  local function cancel()
    finish(nil)
  end
  for _, mode in ipairs({ "i", "n" }) do
    vim.keymap.set(mode, "<CR>", confirm, { buffer = buffer, desc = "Confirm" })
    vim.keymap.set(mode, "<Esc>", cancel, { buffer = buffer, desc = "Cancel" })
    vim.keymap.set(mode, "<C-c>", cancel, { buffer = buffer, desc = "Cancel" })
  end
  vim.keymap.set("n", "q", cancel, { buffer = buffer, desc = "Cancel" })
  vim.api.nvim_create_autocmd("BufLeave", { buffer = buffer, once = true, callback = cancel })
  vim.cmd("startinsert!")
end

return M
