local M = {}
local sessions = {}
local selected = {}
local collapsed_agents = {}
local tabs = {}

-- Terminal navigation must win over provider input. In particular Ctrl J is a
-- newline for a CLI, so a buffer-local, nowait mapping prevents it from sending
-- an accidental prompt submission while the user changes panes.
local function navigation(buffer)
  local keys = {
    ["<C-h>"] = "ForgeWindowLeft",
    ["<C-j>"] = "ForgeWindowDown",
    ["<C-k>"] = "ForgeWindowUp",
    ["<C-l>"] = "ForgeWindowRight",
  }
  for key, command in pairs(keys) do
    vim.keymap.set("t", key, "<C-\\><C-n><cmd>" .. command .. "<cr>", {
      buffer = buffer,
      desc = "Focus adjacent window",
      nowait = true,
      silent = true,
    })
  end
end

local function make_room()
  if
    vim.o.columns < 170
    and not require("forge.features.panels.windows").get("chat")
    and not require("forge.features.panels.windows").get("activity")
    and require("forge.features.panels.windows").get("agents")
  then
    collapsed_agents[vim.api.nvim_get_current_tabpage()] = true
    require("forge.features.panels.windows").hide("agents")
  end
end

-- BR-AG-20: each agent owns one tab rooted in its worktree, so Explorer, files,
-- and terminals show that agent's code. Returns true when the tab was created.
local function agent_tab(task)
  local tab = tabs[task.id]
  if tab and vim.api.nvim_tabpage_is_valid(tab) then
    vim.api.nvim_set_current_tabpage(tab)
    return false
  end
  vim.cmd.tabnew()
  vim.cmd.tcd(vim.fn.fnameescape(task.worktree))
  tab = vim.api.nvim_get_current_tabpage()
  tabs[task.id] = tab
  vim.t.forge_agent = task.id
  vim.t.forge_origin = task.root
  vim.t.forge_tab_label = task.provider .. " · " .. task.prompt
  require("forge.features.workspace").open()
  return true
end

function M.tab(task)
  return agent_tab(task)
end

function M.launch(task)
  agent_tab(task)
  make_room()
  local tab = vim.api.nvim_get_current_tabpage()
  local package = require("forge").root .. "/packages/agent-core"
  local ok, session = pcall(
    require("forge.features.terminal.session").launch,
    { "python3", "-m", "forge_agents.chat", "--root", task.root, task.id },
    {
      slot = "chat",
      position = "right",
      size = 44,
      title = task.provider:upper() .. " · " .. task.prompt,
      root = task.root,
      cwd = task.worktree,
      env = {
        PYTHONPATH = package .. (vim.env.PYTHONPATH and ":" .. vim.env.PYTHONPATH or ""),
        PYTHONDONTWRITEBYTECODE = "1",
      },
      on_exit = function()
        require("forge.features.agents.panel").refresh()
        vim.notify("Chat closed. Open Agents to review its worktree changes.")
      end,
    }
  )
  if not ok then
    require("forge.features.agents.client").request(
      { "cancel", task.id },
      function() end,
      task.root
    )
    return vim.notify(tostring(session), vim.log.levels.ERROR)
  end
  sessions[task.id] = session
  navigation(session.buffer)
  selected[tab] = task.id
  require("forge.features.agents.notifications").track(task)
  require("forge.features.agents.panel").refresh()
  return session
end

function M.new(root)
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buffer].modified then
      return vim.notify(
        "Save buffers and commit or stash changes before opening isolated chat",
        vim.log.levels.WARN
      )
    end
  end
  root = root or require("forge.core.project").origin()
  require("forge.features.agents.providers").choose(function(provider)
    require("forge.features.input").open({
      prompt = provider.label .. " conversation name",
      default = provider.label .. " conversation",
    }, function(title)
      require("forge.features.agents.client").request(
        { "chat", "--provider", provider.id, "--prompt=" .. title },
        M.launch,
        root
      )
    end)
  end)
end

function M.live(task)
  local session = sessions[task.id]
  return session ~= nil and session.exit_code == nil and vim.api.nvim_buf_is_valid(session.buffer)
end

function M.show(task)
  local session = sessions[task.id]
  if not M.live(task) then
    return require("forge.features.agents.actions").logs(task)
  end
  selected[vim.api.nvim_get_current_tabpage()] = task.id
  make_room()
  require("forge.features.terminal.session").show(session, { position = "right", size = 44 })
end

-- Switching agents moves to that agent's tab; the live session reattaches there.
function M.focus(task)
  agent_tab(task)
  if M.live(task) then
    M.show(task)
  else
    require("forge.features.agents.actions").logs(task)
  end
end

function M.toggle()
  if require("forge.features.panels.windows").hide("chat") then
    local tab = vim.api.nvim_get_current_tabpage()
    if collapsed_agents[tab] then
      collapsed_agents[tab] = nil
      require("forge.features.agents.panel").open(false)
    end
    return
  end
  local session = sessions[selected[vim.api.nvim_get_current_tabpage()]]
  if session then
    make_room()
    require("forge.features.terminal.session").show(session, { position = "right", size = 44 })
  else
    require("forge.features.workbench.empty").open(
      "chat",
      { position = "right", size = 40, focus = true }
    )
  end
end

return M
