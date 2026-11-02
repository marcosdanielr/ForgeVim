local M = {}

function M.setup()
  vim.g.mapleader = " "
  vim.g.maplocalleader = ","
  local options = {
    number = true,
    relativenumber = true,
    termguicolors = true,
    signcolumn = "yes",
    splitright = true,
    splitbelow = true,
    ignorecase = true,
    smartcase = true,
    inccommand = "split",
    expandtab = true,
    shiftwidth = 2,
    tabstop = 2,
    undofile = true,
    updatetime = 250,
    timeoutlen = 400,
    completeopt = "menu,menuone,noselect",
    mouse = "a",
    hidden = true,
    exrc = false, -- Never execute project-local editor configuration automatically.
  }
  for name, value in pairs(options) do
    vim.opt[name] = value
  end
  vim.diagnostic.config({
    severity_sort = true,
    virtual_text = false,
    float = { border = "single" },
  })
end

return M
