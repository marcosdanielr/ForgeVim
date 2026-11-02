local M = {}
local workspaces = {}

local function state()
  local tab = vim.api.nvim_get_current_tabpage()
  workspaces[tab] = workspaces[tab] or { sessions = {}, active = 1, splits = {}, tab = tab }
  return workspaces[tab]
end

local function refresh_titles(current)
  for index, session in ipairs(current.sessions) do
    session.title = string.format("Terminal %d/%d", index, #current.sessions)
    local window = vim.fn.bufwinid(session.buffer)
    if window > 0 then
      vim.w[window].forge_panel_title = session.title
    end
  end
  require("forge.features.terminal.tree").refresh(current)
  vim.cmd("redrawstatus")
end

function M.new(split)
  local windows = require("forge.features.panels.windows")
  local current = state()
  current.restore = nil
  local root = require("forge.core.project").root()
  local slot = "terminal"
  local anchor, position, size = nil, "below", nil
  if split then
    local panel = windows.get(vim.b.forge_terminal_slot or "terminal") or windows.get("terminal")
    if not panel then
      return M.new(false)
    end
    if vim.api.nvim_win_get_width(panel.window) < 50 and windows.get("logs") then
      windows.hide("logs")
    end
    size = math.floor((vim.api.nvim_win_get_width(panel.window) - 1) / 2)
    slot = "terminal-split-" .. (#current.sessions + 1)
    anchor, position = panel.window, "right"
  else
    for _, id in ipairs(current.splits) do
      windows.hide(id)
    end
    current.splits = {}
  end
  local session = require("forge.features.terminal.session").launch({ vim.o.shell }, {
    root = root,
    slot = slot,
    title = "Terminal " .. (#current.sessions + 1),
    position = position,
    anchor = anchor,
    size = size,
    on_exit = function()
      refresh_titles(current)
    end,
  })
  session.shell = vim.fn.fnamemodify(vim.o.shell, ":t")
  current.sessions[#current.sessions + 1] = session
  current.active = #current.sessions
  refresh_titles(current)
  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = session.buffer,
    callback = function()
      for index, candidate in ipairs(current.sessions) do
        if candidate == session and current.active ~= index then
          current.active = index
          refresh_titles(current)
        end
      end
    end,
  })
  if split then
    current.splits[#current.splits + 1] = slot
  end
  require("forge.features.terminal.tree").open(current, false)
  return session
end

function M.toggle()
  local windows = require("forge.features.panels.windows")
  local current = state()
  if #current.sessions == 0 then
    if windows.hide("terminal") then
      return
    end
    return M.new(false)
  end
  local visible = windows.get("terminal") ~= nil
  for _, slot in ipairs(current.splits) do
    visible = windows.get(slot) ~= nil or visible
  end
  if visible then
    current.restore = {}
    local slots = { "terminal" }
    vim.list_extend(slots, current.splits)
    for _, slot in ipairs(slots) do
      local panel = windows.get(slot)
      if panel then
        for _, session in ipairs(current.sessions) do
          if session.buffer == panel.buffer then
            current.restore[#current.restore + 1] = session
          end
        end
      end
    end
    windows.hide("terminal-list")
    for index = #slots, 1, -1 do
      windows.hide(slots[index])
    end
    return
  end
  if current.restore and #current.restore > 0 then
    local anchor
    for index, session in ipairs(current.restore) do
      local options = index == 1 and { position = "below" }
        or {
          position = "right",
          anchor = anchor,
          size = math.floor((vim.api.nvim_win_get_width(anchor) - 1) / 2),
        }
      require("forge.features.terminal.session").show(session, options)
      if index == 1 then
        anchor = windows.get(session.slot).window
      end
    end
    require("forge.features.terminal.tree").open(current, false)
    return
  end
  local selected = current.sessions[current.active]
  if not selected then
    return M.new(false)
  end
  selected.slot = "terminal"
  current.splits = {}
  require("forge.features.terminal.session").show(selected, { position = "below" })
  require("forge.features.terminal.tree").open(current, false)
end

function M.select(index)
  local current = state()
  local session = current.sessions[index]
  if not session then
    return
  end
  current.active = index
  current.restore = nil
  local visible = vim.fn.bufwinid(session.buffer)
  if visible > 0 then
    vim.api.nvim_set_current_win(visible)
    if session.exit_code == nil then
      vim.cmd("startinsert")
    end
  else
    session.slot = "terminal"
    require("forge.features.terminal.session").show(session, { position = "below" })
  end
  refresh_titles(current)
  require("forge.features.terminal.tree").open(current, false)
end

function M.cycle(direction)
  local current = state()
  if #current.sessions == 0 then
    return M.new(false)
  end
  M.select((current.active - 1 + direction) % #current.sessions + 1)
end

function M.choose()
  local current = state()
  if #current.sessions == 0 then
    M.new(false)
  end
  if not require("forge.features.panels.windows").get("terminal") then
    M.toggle()
  end
  require("forge.features.terminal.tree").open(current, true)
end

return M
