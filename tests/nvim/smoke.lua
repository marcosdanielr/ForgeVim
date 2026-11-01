local function exercise()
  for _, file in ipairs(vim.fn.glob(require("forge").directory .. "/**/*.lua", false, true)) do
    assert(loadfile(file), "Invalid Lua: " .. file)
  end
  assert(vim.fn.exists(":Forge") == 2)
  assert(vim.fn.exists(":ForgeAgents") == 2)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "one two" })
  vim.cmd("normal! gg0diw")
  assert(vim.api.nvim_get_current_line() == " two", "Native operator changed")
  assert(vim.fn.getreg('"') == "one", "Native register changed")
  vim.bo.modified = false
  vim.cmd("enew")
  local state = require("forge.core.state")
  state.write({ plugins = {}, theme = "habamax" })
  assert(state.read().theme == "habamax")
  local selection = require("forge.languages.selection")
  assert(not selection.enabled("python"), "Language profile enabled without opt-in")
  selection.set("python", true)
  assert(selection.server_enabled("pyright"))
  assert(selection.filetype_enabled("python"))
  selection.set("python", false)
  assert(not selection.server_enabled("pyright"))
  local shortcuts = require("forge.features.shortcuts")
  local selected
  for _, action in ipairs(require("forge.core.actions")) do
    if action.command == "ForgeFiles" then
      selected = action
    end
  end
  assert(shortcuts.validate("<F6>", selected))
  assert(not shortcuts.validate("h", selected), "Native motion override was allowed")
  assert(not shortcuts.validate("<C-w>h", selected), "Native window command override was allowed")
  shortcuts.save(selected, { "<F6>" })
  assert(vim.fn.maparg("<F6>", "n", false, true).desc == selected.label)
  assert(vim.fn.maparg("<C-p>", "n") == "", "Replaced default mapping survived")
  assert(state.read().keymaps.ForgeFiles[1] == "<F6>")
  shortcuts.save(selected, nil)
  assert(vim.fn.maparg("<F6>", "n") == "")
  assert(vim.fn.maparg("<C-p>", "n", false, true).desc == selected.label)
  local done, task = false, nil
  require("forge.features.agents.client").request({ "list" }, function(tasks)
    for _, candidate in ipairs(tasks) do
      if candidate.id == vim.env.FORGE_SMOKE_TASK then
        task = candidate
      end
    end
    done = true
  end, vim.env.FORGE_SMOKE_ROOT)
  assert(
    vim.wait(5000, function()
      return done
    end),
    "Async list timed out"
  )
  assert(task and task.status == "ready")
  local notifications = require("forge.features.agents.notifications")
  local messages = 0
  local notify = vim.notify
  vim.notify = function(message, level, options)
    if tostring(message):find(task.id, 1, true) then
      messages = messages + 1
    end
    notify(message, level, options)
  end
  notifications.track({ id = task.id, root = task.root, status = "running" })
  assert(
    vim.wait(5000, function()
      return messages == 1
    end),
    "Task completion notification missing"
  )
  notifications.toggle()
  assert(not notifications.enabled(), "Notification preference did not persist")
  notifications.track({ id = task.id, root = task.root, status = "running" })
  vim.wait(300)
  assert(messages == 1, "Disabled notifications still fired")
  vim.notify = notify
  require("forge.features.agents.review").open(task)
  assert(
    vim.wait(5000, function()
      return vim.b.forge_review ~= nil
    end),
    "Review buffer timed out"
  )
  assert(vim.bo.filetype == "diff")
  assert(vim.fn.readfile(vim.env.FORGE_SMOKE_ROOT .. "/sample.txt")[1] == "before")
  vim.ui.select = function(choices, _, callback)
    callback(choices[2])
  end
  local mapping = vim.fn.maparg("a", "n", false, true)
  assert(type(mapping.callback) == "function")
  mapping.callback()
  assert(
    vim.wait(5000, function()
      return vim.fn.readfile(vim.env.FORGE_SMOKE_ROOT .. "/sample.txt")[1] == "after"
    end),
    "Accept did not apply reviewed patch"
  )
end

local ok, error = xpcall(exercise, debug.traceback)
if not ok then
  io.stderr:write(error .. "\n")
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
