local M = {}

local function focus(window)
  if not vim.api.nvim_win_is_valid(window) then
    return false
  end
  vim.api.nvim_set_current_win(window)
  return true
end

function M.new(window)
  if focus(window) then
    require("forge.features.terminal").new(false)
  end
end

function M.split(window)
  if focus(window) then
    require("forge.features.terminal").new(true)
  end
end

function M.choose(window)
  if focus(window) then
    require("forge.features.terminal").choose()
  end
end

function M.hide(window)
  if focus(window) then
    require("forge.features.terminal").toggle()
  end
end

function M.render(window, title, width)
  local hints = require("forge.features.workbench.hints")
  local function button(method, label)
    return "%"
      .. window
      .. "@v:lua.require'forge.features.terminal.toolbar'."
      .. method
      .. "@"
      .. label
      .. "%T"
  end
  local controls = " "
    .. button("new", "+ New")
    .. "  "
    .. button("split", "Split")
    .. "  "
    .. button("choose", "List")
    .. "  "
    .. button("hide", width >= 65 and ("Hide " .. hints.get("terminal")) or "Hide")
  local key = hints.command("ForgeTerminalNew")
  local label = title .. "  " .. key .. " new"
  if width < 55 then
    label = title:gsub("Terminal", "Term")
    controls = " "
      .. button("new", "+ New")
      .. "  "
      .. button("choose", "List")
      .. "  "
      .. button("hide", "Hide")
  end
  return "%#ForgeBorder#╭─%#ForgeAccent# "
    .. label:gsub("%%", "%%%%")
    .. "%=%#ForgeMuted#"
    .. controls
    .. "  %#ForgeBorder#╮"
end

return M
