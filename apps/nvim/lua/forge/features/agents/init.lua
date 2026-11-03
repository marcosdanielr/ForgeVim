local M = {}
local client = require("forge.features.agents.client")

local function clean_workspace(message)
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buffer].modified then
      vim.notify(message, vim.log.levels.WARN)
      return false
    end
  end
  return true
end

function M.start(root)
  require("forge.features.agents.chat").new(root)
end

function M.background(root)
  if
    not clean_workspace(
      "Save buffers and commit or stash changes before starting a background task"
    )
  then
    return
  end
  root = root or require("forge.core.project").origin()
  require("forge.features.agents.providers").choose(function(provider)
    require("forge.features.input").open({
      prompt = provider.label .. " background task",
    }, function(prompt)
      client.request({ "start", "--provider", provider.id, "--prompt=" .. prompt }, function(task)
        require("forge.features.agents.notifications").track(task)
        require("forge.features.agents.panel").refresh()
        vim.notify("Agent " .. task.id .. " started. :ForgeAgents shows status.")
      end, root)
    end)
  end)
end

function M.choose()
  require("forge.features.agents.panel").toggle()
end

return M
