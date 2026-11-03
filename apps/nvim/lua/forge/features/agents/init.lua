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

function M.start()
  if
    not clean_workspace(
      "Save buffers and commit or stash changes before starting an agent conversation"
    )
  then
    return
  end
  local root = require("forge.core.project").root()
  require("forge.features.agents.providers").choose(function(provider)
    vim.ui.input({ prompt = provider.label .. " conversation: " }, function(prompt)
      if prompt and prompt:match("%S") then
        client.request({ "chat", "--provider", provider.id, "--prompt=" .. prompt }, function(task)
          require("forge.features.agents.chat").launch(task)
          vim.notify(provider.label .. " conversation started in an isolated worktree")
        end, root)
      end
    end)
  end)
end

function M.background()
  if
    not clean_workspace(
      "Save buffers and commit or stash changes before starting a background task"
    )
  then
    return
  end
  local root = require("forge.core.project").root()
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
