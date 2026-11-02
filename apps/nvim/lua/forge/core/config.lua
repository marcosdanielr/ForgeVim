local M = { options = {} }

function M.setup()
  local defaults = {
    theme = "tokyonight",
    leader = " ",
    localleader = ",",
    workspace = true,
    startup_panels = { files = true, agents = true, navigation = true, chat = true, output = true },
    diagnostic_display = "inline",
    format_on_save = true,
    copilot = false,
    notifications = true,
    nerd_fonts = true,
    languages = {},
    plugin_specs = {},
    tool_paths = {},
  }
  local path = vim.fn.stdpath("config") .. "/lua/user.lua"
  local user = {}
  if vim.uv.fs_stat(path) then
    user = dofile(path)
    assert(type(user) == "table", "user.lua must return a table")
  end
  M.options = vim.tbl_deep_extend("force", defaults, user)
  local saved = require("forge.core.state").read()
  if saved.nerd_fonts ~= nil then
    M.options.nerd_fonts = saved.nerd_fonts
  end
  if saved.leader ~= nil then
    M.options.leader = saved.leader
  end
  local leader = require("forge.features.leader")
  local key, message = leader.normalize(M.options.leader)
  assert(key, message)
  M.options.leader = key
  local local_key, local_message = leader.normalize(M.options.localleader)
  assert(local_key, local_message)
  M.options.localleader = local_key
end

return M
