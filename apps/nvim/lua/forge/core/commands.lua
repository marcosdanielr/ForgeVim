local M = {}

function M.execute(action)
  local ok, error = pcall(action.run)
  if not ok then
    vim.notify(action.label .. ": " .. tostring(error), vim.log.levels.ERROR)
  end
end

function M.palette()
  require("forge.features.picker").select(require("forge.core.actions"), {
    prompt = "Forge commands",
    format_item = function(action)
      return action.label
        .. "  "
        .. table.concat(require("forge.features.shortcuts").keys(action), " / ")
    end,
  }, M.execute)
end

function M.setup()
  for _, action in ipairs(require("forge.core.actions")) do
    vim.api.nvim_create_user_command(action.command, function()
      M.execute(action)
    end, { desc = action.label })
  end
  vim.api.nvim_create_user_command("Forge", M.palette, { desc = "Forge command palette" })
end

return M
