local M = { options = {} }

function M.setup()
  local defaults = {
    theme = "tokyonight",
    workspace = true,
    startup_panels = { files = true, agents = true, navigation = true, chat = true, output = true },
    format_on_save = true,
    copilot = false,
    notifications = true,
    nerd_fonts = false,
    languages = {},
    tool_paths = {},
  }
  local path = vim.fn.stdpath("config") .. "/lua/user.lua"
  local user = {}
  if vim.uv.fs_stat(path) then
    user = dofile(path)
    assert(type(user) == "table", "user.lua must return a table")
  end
  M.options = vim.tbl_deep_extend("force", defaults, user)
end

return M
