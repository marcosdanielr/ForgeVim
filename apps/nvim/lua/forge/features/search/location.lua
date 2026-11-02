-- Reveal a result in the source split without taking focus or writing a file.
local M = {}
local namespace = vim.api.nvim_create_namespace("forge-search-location")

function M.clear(dialog)
  if dialog.revealed_buffer and vim.api.nvim_buf_is_valid(dialog.revealed_buffer) then
    vim.api.nvim_buf_clear_namespace(dialog.revealed_buffer, namespace, 0, -1)
  end
  dialog.revealed_buffer, dialog.revealed_key = nil, nil
end

function M.show(dialog, entry)
  local key = entry.filename .. ":" .. entry.lnum .. ":" .. entry.col .. entry.value.text
  if key == dialog.revealed_key or not vim.api.nvim_win_is_valid(dialog.editor) then
    return
  end
  M.clear(dialog)
  local buffer = vim.fn.bufadd(entry.filename)
  vim.fn.bufload(buffer)
  local actual = vim.api.nvim_buf_get_lines(buffer, entry.lnum - 1, entry.lnum, false)[1]
  if actual ~= entry.value.text then
    return
  end
  vim.api.nvim_win_set_buf(dialog.editor, buffer)
  vim.api.nvim_win_set_cursor(dialog.editor, { entry.lnum, entry.col - 1 })
  local match = entry.value.matches[1]
  vim.api.nvim_buf_set_extmark(buffer, namespace, entry.lnum - 1, match.start, {
    end_row = entry.lnum - 1,
    end_col = match["end"],
    hl_group = "IncSearch",
    priority = 150,
  })
  dialog.revealed_buffer, dialog.revealed_key = buffer, key
end

return M
