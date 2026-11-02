return {
  {
    "nvim-tree/nvim-web-devicons",
    enabled = require("forge.core.config").options.nerd_fonts,
    opts = { color_icons = true, default = true, strict = true },
  },
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope-ui-select.nvim" },
    opts = {
      defaults = { sorting_strategy = "ascending", layout_config = { prompt_position = "top" } },
    },
  },
  { "MagicDuck/grug-far.nvim", cmd = "GrugFar", opts = { headerMaxWidth = 80 } },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    enabled = require("forge.features.plugins").enabled("lewis6991/gitsigns.nvim", true),
    opts = {},
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    enabled = require("forge.features.plugins").enabled("folke/which-key.nvim", true),
    opts = {
      preset = "classic",
      icons = { mappings = require("forge.core.config").options.nerd_fonts },
      spec = {
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git and review" },
        { "<leader>p", group = "Panels" },
        { "<leader>o", group = "Terminals" },
        { "<leader>b", group = "Buffers" },
        { "<leader>a", group = "Agents" },
        { "<leader>d", group = "Debug" },
        { "<leader>u", group = "Preferences" },
        { "<leader>w", group = "Window size" },
        { "<leader>c", group = "Code" },
      },
    },
  },
}
