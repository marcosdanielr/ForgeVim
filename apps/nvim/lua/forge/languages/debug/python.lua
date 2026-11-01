local M = {}

function M.setup(dap)
  dap.adapters.python = { type = "executable", command = "debugpy-adapter" }
  dap.configurations.python = {
    {
      name = "Launch current Python file",
      type = "python",
      request = "launch",
      program = "${file}",
      cwd = "${workspaceFolder}",
      console = "integratedTerminal",
      pythonPath = function()
        local environment = vim.env.VIRTUAL_ENV
        return environment and environment .. "/bin/python" or vim.fn.exepath("python3")
      end,
    },
  }
end

return M
