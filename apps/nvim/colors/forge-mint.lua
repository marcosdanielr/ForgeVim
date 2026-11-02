-- Reuse Tokyo Night syntax without changing its configuration or saved selection.
vim.cmd.colorscheme("tokyonight")
vim.g.colors_name = "forge-mint"
require("forge.features.workbench.palette").setup()
