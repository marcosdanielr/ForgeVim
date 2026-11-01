local M = {}

function M.setup(dap)
  dap.adapters.php = { type = "executable", command = "php-debug-adapter" }
  dap.configurations.php = {
    { name = "Listen for Xdebug", type = "php", request = "launch", port = 9003 },
  }
end

return M
