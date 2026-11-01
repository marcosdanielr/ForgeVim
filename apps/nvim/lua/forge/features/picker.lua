local M = {}

function M.select(items, options, callback)
  if vim.env.FORGE_OFFLINE ~= "1" then
    require("telescope").load_extension("ui-select")
  end
  vim.ui.select(items, options, function(item)
    if item then
      callback(item)
    end
  end)
end

function M.buffer(title, text, filetype)
  vim.cmd("botright new")
  local buffer = vim.api.nvim_get_current_buf()
  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].swapfile = false
  vim.api.nvim_buf_set_name(buffer, title .. "-" .. buffer)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, vim.split(text, "\n", { plain = true }))
  vim.bo[buffer].filetype = filetype or "text"
  vim.bo[buffer].modifiable = false
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buffer, desc = "Close panel" })
  return buffer
end

return M
