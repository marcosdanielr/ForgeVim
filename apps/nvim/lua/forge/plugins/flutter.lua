return {
  {
    "nvim-flutter/flutter-tools.nvim",
    event = {
      "BufReadPre *.dart",
      "BufNewFile *.dart",
      "BufReadPre pubspec.yaml",
      "BufNewFile pubspec.yaml",
    },
    cmd = {
      "FlutterCommands",
      "FlutterRun",
      "FlutterDebug",
      "FlutterDevices",
      "FlutterReload",
      "FlutterRestart",
      "FlutterQuit",
      "FlutterOutlineToggle",
    },
    enabled = require("forge.languages.selection").enabled("dart"),
    dependencies = { "nvim-lua/plenary.nvim", "saghen/blink.cmp", "mfussenegger/nvim-dap" },
    opts = function()
      return {
        debugger = { enabled = true, evaluate_to_string_in_debug_views = false },
        outline = { icons = require("forge.core.config").options.nerd_fonts },
        dev_tools = { autostart = false, auto_open_browser = false },
        widget_guides = { enabled = false },
        lsp = {
          capabilities = require("blink.cmp").get_lsp_capabilities(),
          settings = {
            completeFunctionCalls = true,
            updateImportsOnRename = true,
          },
        },
      }
    end,
  },
}
