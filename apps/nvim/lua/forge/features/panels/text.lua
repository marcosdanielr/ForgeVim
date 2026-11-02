local M = {}

function M.create(title, root, filetype)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buffer, "Forge " .. title .. " " .. buffer)
  vim.bo[buffer].bufhidden = "hide"
  vim.bo[buffer].swapfile = false
  vim.bo[buffer].filetype = filetype or "forge-panel"
  vim.b[buffer].forge_root = root
  return buffer
end

function M.write(buffer, lines)
  if not vim.api.nvim_buf_is_valid(buffer) then
    return
  end
  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.bo[buffer].modifiable = false
end

function M.show(id, title, content, root, filetype)
  local windows = require("forge.features.panels.windows")
  local existing = windows.get(id)
  local buffer = existing and existing.buffer or M.create(title, root, filetype)
  vim.b[buffer].forge_root = root
  if filetype then
    vim.bo[buffer].filetype = filetype
  end
  content = content:gsub("\r\n", "\n"):gsub("\r", "\n")
  local lines = vim.split(content:gsub("\27%[[%d;?]*[ -/]*[@-~]", ""), "\n", { plain = true })
  M.write(buffer, lines)
  windows.show(id, buffer, { position = "below", title = title })
  vim.keymap.set("n", "q", function()
    windows.hide(id)
  end, { buffer = buffer, desc = "Hide panel" })
  return buffer
end

return M
