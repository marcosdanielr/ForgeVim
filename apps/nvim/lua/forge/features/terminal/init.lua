local M = {}
local workspaces = {}

local function state()
  local tab = vim.api.nvim_get_current_tabpage()
  workspaces[tab] = workspaces[tab] or { sessions = {}, active = 1, splits = {} }
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
  vim.cmd("redrawstatus")
end

function M.new(split)
  local windows = require("forge.features.panels.windows")
  local current = state()
  current.restore = nil
  local root = require("forge.core.project").root()
  local slot = "terminal"
  local anchor, position = nil, "below"
  if split then
    local panel = windows.get(vim.b.forge_terminal_slot or "terminal") or windows.get("terminal")
    if not panel then
      return M.new(false)
    end
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
  })
  current.sessions[#current.sessions + 1] = session
  current.active = #current.sessions
  refresh_titles(current)
  if split then
    current.splits[#current.splits + 1] = slot
  end
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
    for index = #slots, 1, -1 do
      windows.hide(slots[index])
    end
    return
  end
  if current.restore and #current.restore > 0 then
    local anchor
    for index, session in ipairs(current.restore) do
      local options = index == 1 and { position = "below" }
        or { position = "right", anchor = anchor }
      require("forge.features.terminal.session").show(session, options)
      if index == 1 then
        anchor = windows.get(session.slot).window
      end
    end
    return
  end
  local selected = current.sessions[current.active]
  if not selected then
    return M.new(false)
  end
  selected.slot = "terminal"
  current.splits = {}
  require("forge.features.terminal.session").show(selected, { position = "below" })
end

function M.cycle(direction)
  local current = state()
  current.restore = nil
  if #current.sessions == 0 then
    return M.new(false)
  end
  current.active = (current.active - 1 + direction) % #current.sessions + 1
  for _, slot in ipairs(current.splits) do
    require("forge.features.panels.windows").hide(slot)
  end
  current.splits = {}
  local session = current.sessions[current.active]
  session.slot = "terminal"
  require("forge.features.terminal.session").show(session, { position = "below" })
end

function M.choose()
  local current = state()
  if #current.sessions == 0 then
    return M.new(false)
  end
  require("forge.features.picker").select(current.sessions, {
    prompt = "Terminals (hiding keeps processes running)",
    format_item = function(session)
      return session.title .. (session.exit_code and " [exited]" or " [running]")
    end,
  }, function(session)
    current.restore = nil
    for index, candidate in ipairs(current.sessions) do
      if candidate == session then
        current.active = index
      end
    end
    for _, slot in ipairs(current.splits) do
      require("forge.features.panels.windows").hide(slot)
    end
    current.splits = {}
    session.slot = "terminal"
    require("forge.features.terminal.session").show(session, { position = "below" })
  end)
end

return M
