local M = {}
local sessions = {}
local selected = {}
local collapsed_agents = {}

local function make_room()
  if vim.o.columns < 170 and require("forge.features.panels.windows").get("agents") then
    collapsed_agents[vim.api.nvim_get_current_tabpage()] = true
    require("forge.features.panels.windows").hide("agents")
  end
end

function M.launch(task)
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
      title = task.provider .. " chat / " .. task.id,
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
  selected[tab] = task.id
  require("forge.features.agents.notifications").track(task)
  require("forge.features.agents.panel").refresh()
  return session
end

function M.new()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buffer].modified then
      return vim.notify(
        "Save buffers and commit or stash changes before opening isolated chat",
        vim.log.levels.WARN
      )
    end
  end
  local root = require("forge.core.project").root()
  require("forge.features.agents.providers").choose(function(provider)
    vim.ui.input(
      { prompt = "Conversation title: ", default = provider.label .. " conversation" },
      function(title)
        if not title or not title:match("%S") then
          return
        end
        require("forge.features.agents.client").request(
          { "chat", "--provider", provider.id, "--prompt=" .. title },
          M.launch,
          root
        )
      end
    )
  end)
end

function M.show(task)
  local session = sessions[task.id]
  if not session then
    return vim.notify(
      "This CLI terminal belongs to its original editor session. Logs and worktree remain available.",
      vim.log.levels.INFO
    )
  end
  selected[vim.api.nvim_get_current_tabpage()] = task.id
  make_room()
  require("forge.features.terminal.session").show(session, { position = "right", size = 44 })
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
    M.new()
  end
end

return M
