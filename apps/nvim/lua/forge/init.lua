local M = {}

function M.setup(directory)
  if vim.fn.has("nvim-0.11") == 0 then
    error("Forge.nvim requires Neovim >= 0.11")
  end
  M.directory = directory
  M.root = vim.fs.dirname(vim.fs.dirname(directory))
  require("forge.core.config").setup()
  require("forge.core.environment").apply()
  require("forge.core.options").setup()
  require("forge.core.commands").setup()
  require("forge.core.keymaps").setup()
  require("forge.core.bootstrap").setup(directory)
end

return M
