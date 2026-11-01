-- BR-LANG-01: profiles are explicit opt-in; installed binaries alone never enable a server.
local M = {}

function M.enabled(name)
  local selected = require("forge.core.state").read().languages or {}
  if selected[name] ~= nil then
    return selected[name]
  end
  return require("forge.core.config").options.languages[name] == true
end

function M.set(name, enabled)
  assert(require("forge.languages.profiles")[name], "Unknown language profile")
  local state = require("forge.core.state").read()
  state.languages = state.languages or {}
  state.languages[name] = enabled
  require("forge.core.state").write(state)
end

function M.server_enabled(server)
  for name, profile in pairs(require("forge.languages.profiles")) do
    if M.enabled(name) and vim.tbl_contains(profile.servers or {}, server) then
      return true
    end
  end
  return false
end

function M.filetype_enabled(filetype)
  for name, profile in pairs(require("forge.languages.profiles")) do
    if M.enabled(name) and vim.tbl_contains(profile.filetypes or {}, filetype) then
      return true
    end
  end
  return false
end

return M
