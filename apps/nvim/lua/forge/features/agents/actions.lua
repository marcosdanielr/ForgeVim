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

-- Enter on a live conversation switches to it; everything else offers choices.
function M.activate(task)
  if task.mode == "interactive" and require("forge.features.agents.chat").live(task) then
    return require("forge.features.agents.chat").focus(task)
  end
  M.open(task)
end

function M.open(task)
  local choices = { "Review changes", "View logs", "Open worktree", "Cancel task", "Reject task" }
  if task.mode == "interactive" then
    if require("forge.features.agents.chat").live(task) then
      table.insert(choices, 1, "Show interactive chat")
    else
      choices[2] = "View saved conversation output"
    end
  elseif task.status == "ready" or task.status == "failed" then
    table.insert(choices, 1, "Continue in " .. task.provider .. " conversation")
  end
  require("forge.features.picker").select(
    choices,
    { prompt = task.prompt .. " [" .. task.status .. "]" },
    function(action)
      if action == "Show interactive chat" then
        require("forge.features.agents.chat").focus(task)
      elseif action == "Continue in " .. task.provider .. " conversation" then
        require("forge.features.agents.client").request({ "resume", task.id }, function(resumed)
          require("forge.features.agents.chat").launch(resumed)
        end, task.root)
      elseif action == "Review changes" then
        require("forge.features.agents.review").open(task)
      elseif action == "View logs" or action == "View saved conversation output" then
        M.logs(task)
      elseif action == "Open worktree" then
        require("forge.features.agents.chat").tab(task)
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
