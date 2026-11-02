local M = {}

local function split()
  if vim.api.nvim_win_get_config(0).relative ~= "" then
    vim.notify("Focus a split window before resizing", vim.log.levels.INFO)
    return false
  end
  return true
end

function M.width(amount)
  if split() then
    vim.cmd("vertical resize " .. string.format("%+d", amount))
  end
end

function M.height(amount)
  if split() then
    vim.cmd("resize " .. string.format("%+d", amount))
  end
end

function M.equalize()
  if split() then
    vim.cmd("wincmd =")
  end
end

return M
