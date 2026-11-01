-- BR-AG-12: notify once on meaningful completion; no polling at editor startup.
local M = {}
local watchers = {}
local active = { queued = true, running = true, cancelling = true }
local messages = {
  ready = "ready for review",
  failed = "failed; inspect logs",
  cancelled = "cancelled",
  interrupted = "interrupted; worker heartbeat expired",
}

function M.enabled()
  local saved = require("forge.core.state").read().notifications
  if saved ~= nil then
    return saved
  end
  return require("forge.core.config").options.notifications
end

local function stop(root)
  local watcher = watchers[root]
  if watcher then
    watcher.timer:stop()
    watcher.timer:close()
    watchers[root] = nil
  end
end

function M.toggle()
  local state = require("forge.core.state").read()
  state.notifications = not M.enabled()
  require("forge.core.state").write(state)
  if not state.notifications then
    for root in pairs(watchers) do
      stop(root)
    end
  end
  vim.notify(
    "Agent notifications "
      .. (state.notifications and "enabled; open :ForgeAgents to watch active tasks" or "disabled")
  )
end

function M.track(task)
  if not M.enabled() or not active[task.status] then
    return
  end
  local root = task.root
  if watchers[root] then
    watchers[root].tasks[task.id] = task.status
    return
  end
  local watcher =
    { tasks = { [task.id] = task.status }, timer = assert(vim.uv.new_timer()), busy = false }
  watchers[root] = watcher
  watcher.timer:start(
    100,
    2000,
    vim.schedule_wrap(function()
      if watcher.busy or not watchers[root] then
        return
      end
      watcher.busy = true
      require("forge.features.agents.client").request(
        { "list" },
        function(tasks)
          watcher.busy = false
          if not watchers[root] or not M.enabled() then
            return
          end
          for _, current in ipairs(tasks) do
            if watcher.tasks[current.id] and not active[current.status] then
              local message = messages[current.status]
              if message then
                local level = (current.status == "failed" or current.status == "interrupted")
                    and vim.log.levels.WARN
                  or vim.log.levels.INFO
                vim.notify(current.provider .. " " .. current.id .. ": " .. message, level)
              end
              watcher.tasks[current.id] = nil
            end
          end
          if next(watcher.tasks) == nil then
            stop(root)
          end
        end,
        root,
        function()
          stop(root)
        end
      )
    end)
  )
end

return M
