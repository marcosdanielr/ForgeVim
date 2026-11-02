local jobs = {}
vim.v.errmsg = ""

local function text(buffer)
  return table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
end

local function exercise()
  for _, file in ipairs(vim.fn.glob(require("forge").directory .. "/**/*.lua", false, true)) do
    assert(loadfile(file), "Invalid Lua: " .. file)
  end
  local root = assert(vim.uv.fs_realpath(vim.env.FORGE_PANEL_ROOT))
  local windows = require("forge.features.panels.windows")
  vim.cmd.edit(root .. "/sample.txt")
  local first_file = vim.api.nvim_get_current_buf()
  vim.cmd.edit(root .. "/second.txt")
  local second_file = vim.api.nvim_get_current_buf()
  require("forge.features.buffers").cycle_previous()
  assert(vim.api.nvim_get_current_buf() == first_file, "Buffer previous skipped source file")
  require("forge.features.buffers").cycle_next()
  assert(vim.api.nvim_get_current_buf() == second_file, "Buffer next did not restore source file")
  assert(vim.o.mouse == "a", "Mouse support disabled")
  dofile(require("forge").root .. "/tests/nvim/workbench.lua")(first_file)
  vim.api.nvim_win_set_buf(windows.editor(), second_file)
  vim.o.shell = "/bin/sh"
  local terminal = require("forge.features.terminal")
  local first = terminal.new(false)
  jobs[#jobs + 1] = first.job
  vim.api.nvim_chan_send(first.job, "printf 'FORGE_TERMINAL_ONE\\n'\n")
  assert(vim.wait(5000, function()
    return text(first.buffer):find("FORGE_TERMINAL_ONE", 1, true)
  end))
  vim.cmd("stopinsert")
  require("forge.features.terminal.toolbar").hide(windows.get("terminal").window)
  assert(not windows.get("terminal"), "Terminal hide control did not hide")
  assert(vim.fn.jobwait({ first.job }, 0)[1] == -1, "Hiding killed a running terminal")
  local second = terminal.new(false)
  jobs[#jobs + 1] = second.job
  vim.cmd("stopinsert")
  terminal.cycle(-1)
  assert(vim.api.nvim_get_current_buf() == first.buffer, "Terminal switching lost its buffer")
  vim.cmd("stopinsert")
  local split = terminal.new(true)
  jobs[#jobs + 1] = split.job
  vim.cmd("stopinsert")
  assert(windows.get("terminal") and windows.get(split.slot), "Terminal split did not open")
  terminal.toggle()
  assert(
    not windows.get("terminal") and not windows.get(split.slot),
    "Terminal split group did not hide"
  )
  terminal.toggle()
  vim.cmd("stopinsert")
  assert(
    windows.get("terminal") and windows.get(split.slot),
    "Terminal split group did not restore"
  )
  terminal.toggle()
  windows.focus_editor()
  assert(vim.api.nvim_get_current_buf() == second_file, "Terminal layout replaced editor buffer")
  local left_action
  for _, action in ipairs(require("forge.core.actions")) do
    if action.command == "ForgeWindowLeft" then
      left_action = action
    end
  end
  require("forge.features.shortcuts").save(left_action, { "<F7>" })
  assert(
    vim.fn.maparg("<F7>", "t"):find("ForgeWindowLeft", 1, true),
    "Terminal shortcut did not follow customization"
  )
  assert(vim.fn.maparg("<C-h>", "t") == "", "Replaced terminal shortcut survived")
  require("forge.features.shortcuts").save(left_action, nil)
  for _, key in ipairs({ "h", "j", "k", "l" }) do
    assert(vim.fn.maparg(key, "n") == "")
  end

  vim.cmd.edit(root .. "/sample.txt")
  local form = require("forge.features.search.form").state(false)
  assert(form.file == root .. "/sample.txt" and not form.project)
  form.search, form.replacement, form.match_case, form.whole_word = "alpha", "omega", true, true
  local command = require("forge.features.search.matches").command(form, form.search)
  assert(command[#command] == form.file, "File scope escaped to project")
  assert(vim.tbl_contains(command, "--case-sensitive"))
  assert(vim.tbl_contains(command, "--word-regexp"))
  dofile(require("forge").root .. "/tests/nvim/replacement.lua")()
  if vim.fn.executable("rg") == 1 then
    local function count(pattern, settings)
      local arguments = { "rg", "--count-matches" }
      vim.list_extend(arguments, require("forge.features.search.options").flags(settings))
      vim.list_extend(arguments, { "--", pattern, root .. "/sample.txt" })
      local result = vim.system(arguments, { text = true }):wait()
      assert(result.code == 0, result.stderr)
      return tonumber(vim.trim(result.stdout))
    end
    assert(
      count("alpha.one", { match_case = false, regex = false }) == 1,
      "Literal search treated dot as regex"
    )
    assert(
      count("alpha", { match_case = true, whole_word = true, regex = false }) == 2,
      "Case-sensitive whole-word search failed"
    )
    assert(
      count("alpha", { match_case = false, whole_word = true, regex = false }) == 3,
      "Case-insensitive whole-word search failed"
    )
  end

  local task = vim.json.decode(table.concat(vim.fn.readfile(vim.env.FORGE_PANEL_TASK), "\n"))
  local session = require("forge.features.agents.chat").launch(task)
  assert(session and session.job > 0, "Chat terminal did not start")
  jobs[#jobs + 1] = session.job
  assert(
    vim.wait(5000, function()
      return text(session.buffer):find("CHAT_READY", 1, true)
    end),
    "Interactive provider did not render"
  )
  vim.cmd("stopinsert")
  require("forge.features.agents.chat").toggle()
  assert(not windows.get("chat"), "Chat did not hide")
  assert(vim.fn.jobwait({ session.job }, 0)[1] == -1, "Hiding stopped chat")
  require("forge.features.agents.panel").open(true)
  assert(
    vim.wait(5000, function()
      return text(windows.get("agents").buffer):find(task.id, 1, true)
    end),
    "Agent panel omitted chat session"
  )
  assert(
    vim.wait(10000, function()
      return session.exit_code ~= nil
    end),
    "Chat did not finish"
  )
  assert(session.exit_code == 0)
  -- Simulate a fresh editor module: durable output must not depend on session tables.
  package.loaded["forge.features.agents.chat"] = nil
  require("forge.features.agents.chat").show(task)
  assert(
    vim.wait(5000, function()
      local logs = windows.get("logs")
      return logs and text(logs.buffer):find("CHAT_READY", 1, true)
    end),
    "Saved conversation output disappeared after reopening"
  )

  assert(vim.v.errmsg == "", "Async panel error: " .. vim.v.errmsg)
  assert(vim.fn.filereadable(root .. "/chat.txt") == 0, "Chat modified source checkout")
  require("forge.features.agents.review").open(task)
  assert(
    vim.wait(5000, function()
      return vim.b.forge_review ~= nil
    end),
    "Chat changes were not reviewable"
  )
  vim.ui.select = function(choices, _, callback)
    callback(choices[2])
  end
  vim.fn.maparg("a", "n", false, true).callback()
  assert(
    vim.wait(5000, function()
      return vim.fn.filereadable(root .. "/chat.txt") == 1
    end),
    "Reviewed chat patch was not accepted"
  )
end

local ok, failure = xpcall(exercise, debug.traceback)
for _, job in ipairs(jobs) do
  pcall(vim.fn.jobstop, job)
end
if ok then
  vim.cmd("qa!")
else
  io.stderr:write(failure .. "\n")
  vim.cmd("cquit 1")
end
