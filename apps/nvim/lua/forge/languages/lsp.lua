local M = {}

function M.setup()
  local capabilities = require("blink.cmp").get_lsp_capabilities()
  local servers = {
    lua_ls = {
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
        },
      },
    },
    gopls = { settings = { gopls = { completeUnimported = true, gofumpt = true } } },
    rust_analyzer = {
      settings = {
        ["rust-analyzer"] = {
          cargo = { allFeatures = true },
          procMacro = { enable = true },
          check = { command = "clippy" },
        },
      },
    },
    pyright = {},
    ts_ls = {},
    astro = {},
    html = {},
    cssls = {},
    clangd = {},
    phpactor = {},
  }
  for name, options in pairs(servers) do
    options.capabilities = capabilities
    vim.lsp.config(name, options)
    local command = vim.lsp.config[name].cmd
    if
      require("forge.languages.selection").server_enabled(name)
      and type(command) == "table"
      and vim.fn.executable(command[1]) == 1
    then
      vim.lsp.enable(name)
    end
  end
end

return M
