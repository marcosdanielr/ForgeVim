-- Tab accepts a visible Copilot suggestion before blink falls back to a literal Tab.
local function accept_copilot()
  local loaded, suggestion = pcall(require, "copilot.suggestion")
  if loaded and suggestion.is_visible() then
    suggestion.accept()
    return true
  end
end

return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = "InsertEnter",
    opts = {
      keymap = {
        preset = "default",
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "snippet_forward", accept_copilot, "fallback" },
      },
      appearance = { use_nvim_cmp_as_default = false },
      completion = { documentation = { auto_show = true }, menu = { auto_show = true } },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      fuzzy = { implementation = "lua" }, -- No native binary download or build at startup.
    },
  },
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    cmd = "Copilot",
    enabled = require("forge.features.plugins").enabled(
      "zbirenbaum/copilot.lua",
      require("forge.core.config").options.copilot
    ),
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        keymap = { accept = "<M-l>", next = "<M-]>", prev = "<M-[>", dismiss = "<C-]>" },
      },
      panel = { enabled = false },
    },
  },
}
