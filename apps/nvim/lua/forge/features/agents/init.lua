local M = {}
local client = require("forge.features.agents.client")

function M.start()
  local root = require("forge.core.project").root()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buffer].modified then
      return vim.notify(
        "Save buffers and commit or stash changes before starting an agent",
        vim.log.levels.WARN
      )
    end
  end
  require("forge.features.agents.providers").choose(function(provider)
    vim.ui.input({ prompt = provider.label .. " task: " }, function(prompt)
      if prompt and prompt:match("%S") then
        client.request({ "start", "--provider", provider.id, "--prompt=" .. prompt }, function(task)
          require("forge.features.agents.notifications").track(task)
          require("forge.features.agents.panel").refresh()
          vim.notify("Agent " .. task.id .. " started. :ForgeAgents shows status.")
        end, root)
      end
    end)
  end)
end

function M.choose()
  require("forge.features.agents.panel").toggle()
end

return M
