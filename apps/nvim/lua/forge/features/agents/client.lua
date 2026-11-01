local M = {}

function M.request(arguments, callback, root, on_error)
  root = root or require("forge.core.project").root()
  local package = require("forge").root .. "/packages/agent-core"
  local command = { "python3", "-m", "forge_agents", "--root", root }
  vim.list_extend(command, arguments)
  local environment = {
    PYTHONPATH = package .. (vim.env.PYTHONPATH and ":" .. vim.env.PYTHONPATH or ""),
    PYTHONDONTWRITEBYTECODE = "1",
  }
  vim.system(command, { text = true, env = environment }, function(result)
    vim.schedule(function()
      local ok, response = pcall(vim.json.decode, result.stdout or "")
      if not ok or not response.ok then
        vim.notify(
          ok and response.error or (result.stderr or "Invalid agent response"),
          vim.log.levels.ERROR
        )
        return
      end
      callback(response.data)
    end)
  end)
end

return M
