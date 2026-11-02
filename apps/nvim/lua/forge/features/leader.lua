local M = {}

function M.normalize(value)
  if value == "<Space>" or value == "Space" then
    value = " "
  end
  if type(value) ~= "string" or vim.fn.strchars(value) ~= 1 or value:find("[%c]") then
    return nil, "Choose one printable key, such as Space, comma, or backslash"
  end
  return value
end

function M.save(value)
  local key, message = M.normalize(value)
  if not key then
    return vim.notify(message, vim.log.levels.WARN)
  end
  local state = require("forge.core.state").read()
  state.leader = key
  require("forge.core.state").write(state)
  vim.notify("Leader saved. Restart Forge to rebuild all mappings.")
end

function M.choose()
  local choices = {
    { label = "Space (default)", key = " " },
    { label = "Comma", key = "," },
    { label = "Backslash", key = string.char(92) },
    { label = "Custom key" },
  }
  require("forge.features.picker").select(choices, {
    prompt = "Leader key (applies after restart)",
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if item.key then
      return M.save(item.key)
    end
    vim.ui.input({ prompt = "Leader key: " }, function(key)
      if key then
        M.save(key)
      end
    end)
  end)
end

return M
