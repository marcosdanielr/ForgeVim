return {
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
    opts = { integrations = { diffview = true } },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      enhanced_diff_hl = true,
      view = { merge_tool = { layout = "diff3_mixed", disable_diagnostics = true } },
      keymaps = {
        view = {
          {
            "n",
            "<leader>co",
            function()
              require("diffview.actions").conflict_choose("ours")()
            end,
            { desc = "Choose ours at conflict" },
          },
          {
            "n",
            "<leader>ct",
            function()
              require("diffview.actions").conflict_choose("theirs")()
            end,
            { desc = "Choose theirs at conflict" },
          },
          {
            "n",
            "<leader>cb",
            function()
              require("diffview.actions").conflict_choose("base")()
            end,
            { desc = "Choose base at conflict" },
          },
        },
      },
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    opts = function()
      local icons = require("forge.core.config").options.nerd_fonts
      return {
        view = { width = 30 },
        on_attach = require("forge.features.explorer").attach,
        update_focused_file = { enable = true },
        renderer = {
          indent_markers = { enable = true },
          icons = {
            show = { file = icons, folder = icons, folder_arrow = true, git = icons },
            glyphs = { folder = { arrow_closed = "▸", arrow_open = "▾" } },
          },
        },
        actions = { open_file = { quit_on_open = false } },
      }
    end,
  },
}
