local M = {}

function M.attach(buffer)
  local api = require("nvim-tree.api")
  api.config.mappings.default_on_attach(buffer)
  for _, key in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>" }) do
    pcall(vim.keymap.del, "n", key, { buffer = buffer })
  end
  local function open()
    local node = api.tree.get_node_under_cursor()
    if not node then
      return
    end
    if node.type == "directory" then
      return api.node.open.edit()
    end
    if node.absolute_path then
      require("forge.features.panels.windows").focus_editor()
      vim.cmd.edit(vim.fn.fnameescape(node.absolute_path))
    end
  end
  vim.keymap.set(
    "n",
    "h",
    api.node.navigate.parent_close,
    { buffer = buffer, desc = "Collapse folder / parent" }
  )
  for _, key in ipairs({ "l", "<CR>", "<2-LeftMouse>" }) do
    vim.keymap.set("n", key, open, { buffer = buffer, desc = "Expand folder / open file" })
  end
end

return M
