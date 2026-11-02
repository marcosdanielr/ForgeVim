local M = {}

function M.logs(task)
  require("forge.features.agents.client").request({ "logs", task.id }, function(log)
    require("forge.features.panels.text").show(
      "logs",
      task.provider .. " / " .. task.id,
      log ~= "" and log or "No output yet.",
      task.root,
      "log"
    )
  end, task.root)
end

function M.open(task)
  local choices = { "Review changes", "View logs", "Open worktree", "Cancel task", "Reject task" }
  if task.mode == "interactive" then
    table.insert(choices, 1, "Show interactive chat")
  end
  require("forge.features.picker").select(
    choices,
    { prompt = task.prompt .. " [" .. task.status .. "]" },
    function(action)
      if action == "Show interactive chat" then
        require("forge.features.agents.chat").show(task)
      elseif action == "Review changes" then
        require("forge.features.agents.review").open(task)
      elseif action == "View logs" then
        M.logs(task)
      elseif action == "Open worktree" then
        vim.cmd.tabnew()
        vim.cmd.tcd(vim.fn.fnameescape(task.worktree))
        require("forge.features.workspace").open()
      else
        local command = action == "Cancel task" and "cancel" or "reject"
        require("forge.features.agents.client").request({ command, task.id }, function()
          require("forge.features.agents.panel").refresh()
          vim.notify(
            command == "cancel" and "Cancellation requested" or "Rejected; worktree preserved"
          )
        end, task.root)
      end
    end
  )
end

return M
