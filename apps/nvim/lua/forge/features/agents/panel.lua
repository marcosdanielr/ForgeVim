local M = {}
local states = {}
local active = { queued = true, running = true, cancelling = true }
local group = vim.api.nvim_create_augroup("ForgeAgentPanels", { clear = true })
vim.api.nvim_create_autocmd("TabEnter", {
  group = group,
  callback = function()
    M.refresh()
  end,
})

local function stop(state)
  for root in pairs(state.watching) do
    require("forge.features.agents.watch").unsubscribe(root, "panel:" .. state.tab)
  end
  state.watching = {}
end

vim.api.nvim_create_autocmd("TabLeave", {
  group = group,
  callback = function()
    local state = states[vim.api.nvim_get_current_tabpage()]
    if state then
      stop(state)
    end
  end,
})

local function visible(state)
  local panel = require("forge.features.panels.windows").get("agents", state.tab)
  return vim.api.nvim_get_current_tabpage() == state.tab
    and states[state.tab] == state
    and panel ~= nil
    and panel.buffer == state.buffer
end

local function summarize(state)
  local count = 0
  for _, tasks in pairs(state.tasks) do
    for _, task in ipairs(tasks) do
      if active[task.status] then
        count = count + 1
      end
    end
  end
  vim.t[state.tab].forge_active_agent_count = count
  vim.cmd("redrawtabline")
  require("forge.features.agents.panel_view").render(state)
end

-- One panel lists every registered project; each project has its own task store.
function M.refresh()
  local state = states[vim.api.nvim_get_current_tabpage()]
  if not state or not visible(state) then
    return
  end
  local watch = require("forge.features.agents.watch")
  state.roots = require("forge.features.agents.projects").list()
  local listed = {}
  for _, root in ipairs(state.roots) do
    listed[root] = true
    if not vim.uv.fs_stat(root .. "/.forge/state.sqlite3") then
      state.tasks[root] = {}
    else
      local added = watch.subscribe(root, "panel:" .. state.tab, function(tasks)
        if not visible(state) then
          stop(state)
          return
        end
        state.tasks[root] = tasks
        summarize(state)
      end, function(error)
        watch.unsubscribe(root, "panel:" .. state.tab)
        state.watching[root] = nil
        state.errors[root] = error
        if visible(state) then
          require("forge.features.agents.panel_view").render(state)
        end
      end)
      state.watching[root] = true
      if not added then
        watch.refresh(root)
      end
    end
  end
  for root in pairs(state.watching) do
    if not listed[root] then
      watch.unsubscribe(root, "panel:" .. state.tab)
      state.watching[root] = nil
      state.tasks[root] = nil
    end
  end
  summarize(state)
end

function M.open(focus, placement)
  local tab = vim.api.nvim_get_current_tabpage()
  local state = states[tab]
  if not state or not vim.api.nvim_buf_is_valid(state.buffer) then
    if state then
      stop(state)
    end
    local root = require("forge.core.project").origin()
    state = {
      root = root,
      tab = tab,
      roots = {},
      tasks = {},
      errors = {},
      watching = {},
      buffer = require("forge.features.panels.text").create("Agents", root, "forge-agents"),
    }
    states[tab] = state
    local options = { buffer = state.buffer }
    local function selected()
      return (vim.b[state.buffer].forge_agent_rows or {})[tostring(
        vim.api.nvim_win_get_cursor(0)[1]
      )]
    end
    -- New work targets the project under the cursor, else the current checkout.
    local function target()
      local entry = selected()
      return entry and entry.root or nil
    end
    local function map(key, description, run)
      vim.keymap.set("n", key, run, vim.tbl_extend("force", options, { desc = description }))
    end
    map("n", "New agent conversation", function()
      require("forge.features.agents").start(target())
    end)
    map("b", "New background task", function()
      require("forge.features.agents").background(target())
    end)
    map("a", "Add project", function()
      require("forge.features.agents.projects").prompt_add()
    end)
    map("x", "Remove project from Forge", function()
      local entry = selected()
      if entry and entry.project then
        require("forge.features.agents.projects").remove(entry.root)
      end
    end)
    map("r", "Refresh agents", M.refresh)
    map("q", "Hide agents", M.toggle)
    local function activate()
      local entry = selected()
      if not entry then
        return
      end
      if entry.action == "new" then
        require("forge.features.agents").start(target())
      elseif entry.action == "background" then
        require("forge.features.agents").background(target())
      elseif entry.action == "add" then
        require("forge.features.agents.projects").prompt_add()
      elseif entry.action == "refresh" then
        M.refresh()
      elseif entry.project then
        require("forge.features.agents.projects").open(entry.root)
      elseif entry.task then
        require("forge.features.agents.actions").activate(entry.task)
      end
    end
    for _, key in ipairs({ "<CR>", "<2-LeftMouse>" }) do
      map(key, "Open agent or project", activate)
    end
    map("v", "Review selected task", function()
      local entry = selected()
      if entry and entry.task then
        require("forge.features.agents.review").open(entry.task)
      end
    end)
    map("L", "Selected task logs", function()
      local entry = selected()
      if entry and entry.task then
        require("forge.features.agents.actions").logs(entry.task)
      end
    end)
    vim.api.nvim_create_autocmd("BufEnter", {
      buffer = state.buffer,
      callback = function()
        M.refresh()
      end,
    })
  end
  require("forge.features.agents.panel_view").render(state)
  local windows = require("forge.features.panels.windows")
  local neighbor = windows.get("activity") or windows.get("chat")
  placement = placement
    or (neighbor and { anchor = neighbor.window, position = "below", size = 18 })
    or {}
  windows.show(
    "agents",
    state.buffer,
    vim.tbl_extend("force", {
      title = "Agents  /  n new  a project  Enter open",
      focus = focus,
      size = 36,
      on_hide = function()
        stop(state)
      end,
    }, placement)
  )
  M.refresh()
end

function M.toggle()
  if not require("forge.features.panels.windows").hide("agents") then
    M.open(true)
  end
end

return M
