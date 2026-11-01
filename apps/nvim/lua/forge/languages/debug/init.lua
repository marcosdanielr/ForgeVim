local M = {}

function M.setup()
  local dap, ui = require("dap"), require("dapui")
  ui.setup({
    layouts = {
      { elements = { "scopes", "breakpoints", "stacks", "watches" }, size = 40, position = "left" },
      { elements = { "repl", "console" }, size = 10, position = "bottom" },
    },
  })
  require("nvim-dap-virtual-text").setup({ enabled = false })
  require("dap-go").setup()
  for _, language in ipairs({ "native", "node", "php", "python" }) do
    require("forge.languages.debug." .. language).setup(dap)
  end
  dap.listeners.after.event_initialized.forge = function()
    ui.open()
  end
  dap.listeners.before.event_terminated.forge = function()
    ui.close()
  end
  dap.listeners.before.event_exited.forge = function()
    ui.close()
  end
end

function M.launch_json()
  require("dap.ext.vscode").load_launchjs(
    require("forge.core.project").root() .. "/.vscode/launch.json",
    {
      ["pwa-node"] = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
      codelldb = { "rust", "c", "cpp" },
      php = { "php" },
      python = { "python" },
    }
  )
  vim.notify("Loaded launch.json from this trusted project")
end

return M
