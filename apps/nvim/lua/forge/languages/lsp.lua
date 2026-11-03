local M = {}

-- Some lspconfig servers define cmd as a function; name their executable explicitly.
local function_command_binaries = {
  ts_ls = "typescript-language-server",
  astro = "astro-ls",
  html = "vscode-html-language-server",
  cssls = "vscode-css-language-server",
}

local function executable(name)
  local command = vim.lsp.config[name].cmd
  local binary = type(command) == "table" and command[1] or function_command_binaries[name]
  return binary ~= nil and vim.fn.executable(binary) == 1
end

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
    if require("forge.languages.selection").server_enabled(name) and executable(name) then
      vim.lsp.enable(name)
    end
  end
end

return M
