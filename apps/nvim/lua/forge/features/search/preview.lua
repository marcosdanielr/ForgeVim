local M = {}

local function instance()
  if vim.bo.filetype ~= "grug-far" then
    vim.notify("Open a replacement preview first with :ForgeReplace", vim.log.levels.INFO)
    return
  end
  return require("grug-far").get_instance(0)
end

function M.apply()
  if require("forge.features.search.picker").apply(true) then
    return
  end
  local preview = instance()
  if preview then
    preview:replace()
  end
end

function M.apply_click(window)
  if vim.api.nvim_win_is_valid(window) then
    vim.api.nvim_set_current_win(window)
    M.apply()
  end
end

function M.help_click(window)
  if not vim.api.nvim_win_is_valid(window) then
    return
  end
  vim.api.nvim_set_current_win(window)
  local preview = instance()
  if preview then
    preview:help()
  end
end

function M.header(window, width)
  local key = require("forge.features.workbench.hints").command("ForgeApplyReplacement")
  local label = width >= 60 and "Apply all · " .. key or "Apply all"
  return "%#ForgeBorder#╭─%#ForgeAccent# Search & Replace %=%#ForgeBadge#%"
    .. window
    .. "@v:lua.require'forge.features.search.preview'.apply_click@ "
    .. label:gsub("%%", "%%%%")
    .. " %T"
    .. "%#ForgeMuted# %"
    .. window
    .. "@v:lua.require'forge.features.search.preview'.help_click@ Help %T %#ForgeBorder#╮"
end

return M
