local M = {}

function M.setup(dap)
  dap.adapters["pwa-node"] = {
    type = "server",
    host = "127.0.0.1",
    port = "${port}",
    executable = { command = "js-debug-adapter", args = { "${port}", "127.0.0.1" } },
  }
  for _, language in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
    dap.configurations[language] = {
      {
        name = "Launch current file (compiled JS or runtime-supported TS)",
        type = "pwa-node",
        request = "launch",
        program = "${file}",
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        console = "integratedTerminal",
      },
      {
        name = "Attach to Node process",
        type = "pwa-node",
        request = "attach",
        processId = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
        sourceMaps = true,
      },
    }
  end
end

return M
