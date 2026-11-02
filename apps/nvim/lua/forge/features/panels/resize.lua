-- Resize moves a visible divider in the requested direction, regardless of focus.
local M = {}

local function split()
  if vim.api.nvim_win_get_config(0).relative ~= "" then
    vim.notify("Focus a split window before resizing", vim.log.levels.INFO)
    return false
  end
  return true
end

local function resize(axis, direction, positive, negative)
  if not split() then
    return
  end
  local current = vim.fn.winnr()
  local amount = direction
  if vim.fn.winnr(positive) == current then
    if vim.fn.winnr(negative) == current then
      return vim.notify("No " .. axis .. " divider to move", vim.log.levels.INFO)
    end
    amount = -amount
  end
  local command = axis == "vertical" and "vertical resize " or "resize "
  vim.cmd(command .. string.format("%+d", amount))
end

function M.width(direction)
  resize("vertical", direction, "l", "h")
end

function M.height(direction)
  resize("horizontal", direction, "j", "k")
end

function M.equalize()
  if split() then
    vim.cmd("wincmd =")
  end
end

return M
