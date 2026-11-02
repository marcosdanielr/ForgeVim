local M = {}

function M.ask(title, value, callback)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { value })
  vim.bo[buffer].bufhidden = "wipe"
  local width = math.max(20, math.min(66, vim.o.columns - 6))
  local window = vim.api.nvim_open_win(buffer, true, {
    relative = "editor",
    width = width,
    height = 1,
    row = math.max(1, math.floor(vim.o.lines / 2) - 2),
    col = math.max(1, math.floor((vim.o.columns - width) / 2)),
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
    footer = " Enter save · Esc cancel ",
    footer_pos = "center",
  })
  local function close(accept)
    local result = vim.api.nvim_buf_get_lines(buffer, 0, 1, false)[1]
    vim.cmd("stopinsert")
    if vim.api.nvim_win_is_valid(window) then
      vim.api.nvim_win_close(window, true)
    end
    if accept then
      callback(result)
    end
  end
  vim.keymap.set({ "i", "n" }, "<CR>", function()
    close(true)
  end, { buffer = buffer })
  vim.keymap.set({ "i", "n" }, "<Esc>", function()
    close(false)
  end, { buffer = buffer })
  vim.api.nvim_win_set_cursor(window, { 1, #value })
  vim.cmd("startinsert!")
end

return M
