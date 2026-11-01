local M = {}

function M.setup(dap)
  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = { command = "codelldb", args = { "--port", "${port}" } },
  }
  local configuration = {
    name = "Launch compiled binary",
    type = "codelldb",
    request = "launch",
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    program = function()
      return vim.fn.input(
        "Built binary: ",
        require("forge.core.project").root() .. "/target/debug/",
        "file"
      )
    end,
  }
  for _, language in ipairs({ "rust", "c", "cpp" }) do
    dap.configurations[language] = { vim.deepcopy(configuration) }
  end
end

return M
