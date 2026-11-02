local M = {}
local themes = { "habamax", "default", "tokyonight", "catppuccin", "rose-pine" }

function M.apply(name)
  local ok, error = pcall(vim.cmd.colorscheme, name)
  if not ok then
    vim.notify(tostring(error), vim.log.levels.ERROR)
    return false
  end
  return true
end

function M.restore()
  local selected = require("forge.core.state").read().theme
  if not M.apply(selected or require("forge.core.config").options.theme) then
    M.apply("habamax")
  end
end

function M.choose()
  require("forge.features.picker").select(
    themes,
    { prompt = "Theme (applied and saved)" },
    function(name)
      if M.apply(name) then
        local state = require("forge.core.state").read()
        state.theme = name
        require("forge.core.state").write(state)
      end
    end
  )
end

return M
