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
          vim.notify("Agent " .. task.id .. " started. :ForgeAgents shows status.")
        end, root)
      end
    end)
  end)
end

function M.choose()
  local root = require("forge.core.project").root()
  client.request({ "list" }, function(tasks)
    for _, task in ipairs(tasks) do
      require("forge.features.agents.notifications").track(task)
    end
    if #tasks == 0 then
      return vim.notify("No tasks. Use :ForgeAgentStart")
    end
    require("forge.features.picker").select(tasks, {
      prompt = "Agents (open again to refresh)",
      format_item = function(task)
        return task.id .. " [" .. task.status .. "] " .. task.prompt:gsub("\n", " "):sub(1, 70)
      end,
    }, function(task)
      require("forge.features.picker").select(
        { "Review changes", "View logs", "Open worktree", "Cancel task", "Reject task" },
        {
          prompt = task.id .. " [" .. task.status .. "]",
        },
        function(action)
          if action == "Review changes" then
            require("forge.features.agents.review").open(task)
          elseif action == "View logs" then
            client.request({ "logs", task.id }, function(log)
              require("forge.features.picker").buffer("ForgeLog-" .. task.id, log)
            end, task.root)
          elseif action == "Open worktree" then
            vim.cmd.tabnew()
            vim.cmd.tcd(vim.fn.fnameescape(task.worktree))
            vim.notify("Worktree opened in a separate tab. Use :ForgeFiles to browse.")
          elseif action == "Cancel task" then
            client.request({ "cancel", task.id }, function()
              vim.notify("Cancellation requested")
            end, task.root)
          else
            client.request({ "reject", task.id }, function()
              vim.notify("Rejected; worktree preserved")
            end, task.root)
          end
        end
      )
    end)
  end, root)
end

return M
