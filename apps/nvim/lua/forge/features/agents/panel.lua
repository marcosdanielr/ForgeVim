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
  require("forge.features.agents.watch").unsubscribe(state.root, "panel:" .. state.tab)
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

function M.refresh()
  local state = states[vim.api.nvim_get_current_tabpage()]
  if not state or not visible(state) then
    return
  end
  if not vim.uv.fs_stat(state.root .. "/.forge/state.sqlite3") then
    state.tasks = {}
    vim.t.forge_active_agent_count = 0
    require("forge.features.agents.panel_view").render(state)
    return
  end
  local watch = require("forge.features.agents.watch")
  local added = watch.subscribe(state.root, "panel:" .. state.tab, function(tasks)
    if not visible(state) then
      stop(state)
      return
    end
    state.tasks = tasks
    local count = 0
    for _, task in ipairs(tasks) do
      if active[task.status] then
        count = count + 1
      end
    end
    vim.t.forge_active_agent_count = count
    vim.cmd("redrawtabline")
    require("forge.features.agents.panel_view").render(state)
  end, function(error)
    stop(state)
    if visible(state) then
      require("forge.features.agents.panel_view").render(state, error)
    end
  end)
  if not added then
    watch.refresh(state.root)
  end
end

function M.open(focus)
  local tab = vim.api.nvim_get_current_tabpage()
  local root = require("forge.core.project").root()
  local state = states[tab]
  if not state or state.root ~= root or not vim.api.nvim_buf_is_valid(state.buffer) then
    if state then
      stop(state)
    end
    state = {
      root = root,
      tab = tab,
      tasks = {},
      buffer = require("forge.features.panels.text").create("Agents", root, "forge-agents"),
    }
    states[tab] = state
    local options = { buffer = state.buffer }
    local function selected()
      return (vim.b[state.buffer].forge_agent_rows or {})[tostring(
        vim.api.nvim_win_get_cursor(0)[1]
      )]
    end
    vim.keymap.set("n", "n", function()
      require("forge.features.agents").start()
    end, vim.tbl_extend("force", options, { desc = "New agent task" }))
    vim.keymap.set("n", "c", function()
      require("forge.features.agents.chat").new()
    end, vim.tbl_extend("force", options, { desc = "New CLI chat" }))
    vim.keymap.set(
      "n",
      "r",
      M.refresh,
      vim.tbl_extend("force", options, { desc = "Refresh agents" })
    )
    vim.keymap.set("n", "q", M.toggle, vim.tbl_extend("force", options, { desc = "Hide agents" }))
    for _, key in ipairs({ "<CR>", "<2-LeftMouse>" }) do
      vim.keymap.set("n", key, function()
        local task = selected()
        if task then
          require("forge.features.agents.actions").open(task)
        end
      end, vim.tbl_extend("force", options, { desc = "Agent actions" }))
    end
    vim.keymap.set("n", "v", function()
      local task = selected()
      if task then
        require("forge.features.agents.review").open(task)
      end
    end, vim.tbl_extend("force", options, { desc = "Review selected task" }))
    vim.keymap.set("n", "L", function()
      local task = selected()
      if task then
        require("forge.features.agents.actions").logs(task)
      end
    end, vim.tbl_extend("force", options, { desc = "Selected task logs" }))
    vim.api.nvim_create_autocmd("BufEnter", {
      buffer = state.buffer,
      callback = function()
        M.refresh()
      end,
    })
  end
  require("forge.features.agents.panel_view").render(state)
  require("forge.features.panels.windows").show("agents", state.buffer, {
    title = "Agents  /  n task  c chat  Enter actions",
    focus = focus,
    size = 36,
    on_hide = function()
      stop(state)
    end,
  })
  M.refresh()
end

function M.toggle()
  if not require("forge.features.panels.windows").hide("agents") then
    M.open(true)
  end
end

return M
