local M = {}

function M.setup()
  vim.g.mapleader = require("forge.core.config").options.leader
  vim.g.maplocalleader = require("forge.core.config").options.localleader
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
    clipboard = "unnamedplus",
    mouse = "a",
    hidden = true,
    exrc = false, -- Never execute project-local editor configuration automatically.
  }
  for name, value in pairs(options) do
    vim.opt[name] = value
  end
  require("forge.features.diagnostics").setup()
end

return M
