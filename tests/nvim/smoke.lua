local function exercise()
  for _, file in ipairs(vim.fn.glob(require("forge").directory .. "/**/*.lua", false, true)) do
    assert(loadfile(file), "Invalid Lua: " .. file)
  end
  local brand = require("forge.features.workspace.brand")
  assert(#brand.lines(100) == 5, "Dashboard wordmark missing")
  assert(#brand.lines(30) == 1, "Narrow dashboard did not use compact wordmark")
  assert(vim.fn.exists(":Forge") == 2)
  assert(vim.fn.exists(":ForgeAgents") == 2)
  assert(vim.o.clipboard:find("unnamedplus", 1, true), "System clipboard is disabled")
  assert(vim.fn.maparg("<C-c>", "x", false, true).desc == "Copy selection to system clipboard")
  assert(vim.fn.maparg("<C-v>", "i", false, true).desc == "Paste from system clipboard")
  for command, key in pairs({
    ForgeGit = " gg",
    ForgeFiles = " ff",
    ForgeBufferSearch = " fb",
    ForgeReplace = " fr",
    ForgeTerminal = " ot",
    ForgeTree = " b",
  }) do
    assert(vim.fn.maparg(key, "n", false, true).desc, command .. " is not a Leader mapping")
  end
  for _, key in ipairs({ "<C-S-g>", "<C-p>", "<C-f>", "<C-S-h>", "<C-b>" }) do
    assert(vim.fn.maparg(key, "n") == "", "Legacy Forge shortcut remains: " .. key)
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "one two" })
  vim.cmd("normal! gg0diw")
  assert(vim.api.nvim_get_current_line() == " two", "Native operator changed")
  assert(vim.fn.getreg('"') == "one", "Native register changed")
  vim.bo.modified = false
  vim.cmd("enew")
  local original_number = vim.wo.number
  local workspace = require("forge.features.workspace").open()
  assert(vim.bo.filetype == "forge-workspace")
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  local mouse_action = vim.fn.maparg("<2-LeftMouse>", "n", false, true).callback
  assert(type(mouse_action) == "function", "Workspace mouse action missing")
  mouse_action()
  assert(vim.bo.filetype == "forge-workspace", "Workspace heading triggered an action")
  assert(
    vim.wait(5000, function()
      local text = table.concat(vim.api.nvim_buf_get_lines(workspace, 0, -1, false), "\n")
      return text:find("changed paths", 1, true) and not text:find("Reading project", 1, true)
    end),
    "Workspace Git snapshot timed out"
  )
  for _, key in ipairs({ "h", "j", "k", "l" }) do
    assert(vim.fn.maparg(key, "n") == "", "Workspace overrides native cursor key " .. key)
  end
  vim.cmd("enew")
  assert(vim.wo.number == original_number, "Workspace leaked window options into editor")
  vim.cmd("vsplit")
  local right = vim.api.nvim_get_current_win()
  vim.fn.maparg("<C-h>", "n", false, true).callback()
  local left = vim.api.nvim_get_current_win()
  assert(left ~= right, "Ctrl H did not focus the left pane")
  vim.fn.maparg("<C-l>", "n", false, true).callback()
  assert(vim.api.nvim_get_current_win() == right, "Ctrl L did not restore the right pane")
  vim.cmd("split")
  local bottom = vim.api.nvim_get_current_win()
  vim.fn.maparg("<C-k>", "n", false, true).callback()
  assert(vim.api.nvim_get_current_win() ~= bottom, "Ctrl K did not focus the upper pane")
  vim.fn.maparg("<C-j>", "n", false, true).callback()
  assert(vim.api.nvim_get_current_win() == bottom, "Ctrl J did not restore the lower pane")
  vim.cmd("only")
  local state = require("forge.core.state")
  state.write({ plugins = {}, theme = "habamax" })
  assert(state.read().theme == "habamax")
  local plugin_options = require("forge.core.config").options
  assert(#plugin_options.plugin_specs == 0, "Personal plugins enabled by default")
  plugin_options.plugin_specs = { { import = "personal.plugins", opts = { fixture = true } } }
  local specifications = require("forge.features.plugins").spec()
  assert(specifications[1].import == "personal.plugins", "Personal plugin import was lost")
  specifications[1].opts.fixture = false
  assert(plugin_options.plugin_specs[1].opts.fixture, "Plugin resolution mutated personal config")
  plugin_options.plugin_specs = {}
  assert(
    not vim.uv.fs_stat(require("forge").directory .. "/lua/forge/plugins/flutter.lua"),
    "Flutter plugin is still bundled"
  )
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
