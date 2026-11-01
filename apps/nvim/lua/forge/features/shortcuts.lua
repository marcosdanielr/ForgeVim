-- BR-ED-09: named actions own shortcuts; preferences are data, never executable Lua.
local M = {}

function M.keys(action)
  local overrides = require("forge.core.state").read().keymaps or {}
  return overrides[action.command] or action.keys
end

function M.validate(key, action, restoring)
  if not key or key == "" or #key > 80 or key:find("[\r\n]") then
    return false, "Enter a key such as <leader>xf or <F6>"
  end
  if not restoring and (#key == 1 or key:lower():find("<c%-w>") or key == ":") then
    return false, "Keep native single-key motions and Ctrl-W; use a leader or modified key"
  end
  local existing = vim.fn.maparg(key, "n", false, true)
  if existing.lhs and existing.desc ~= action.label then
    return false, "Already mapped: " .. (existing.desc or existing.rhs or key)
  end
  return true
end

function M.save(action, keys)
  for _, key in ipairs(keys or action.keys) do
    local valid, message = M.validate(key, action, keys == nil)
    if not valid then
      return vim.notify(message, vim.log.levels.WARN)
    end
  end
  local state = require("forge.core.state").read()
  state.keymaps = state.keymaps or {}
  local previous = M.keys(action)
  local ok, error = pcall(require("forge.core.keymaps").apply, action, keys or action.keys)
  if not ok then
    require("forge.core.keymaps").apply(action, previous)
    return vim.notify(tostring(error), vim.log.levels.ERROR)
  end
  state.keymaps[action.command] = keys
  require("forge.core.state").write(state)
  vim.notify("Shortcuts saved and applied")
end

function M.choose()
  local picker = require("forge.features.picker")
  picker.select(require("forge.core.actions"), {
    prompt = "Configure shortcuts (normal mode)",
    format_item = function(action)
      return action.label .. "  " .. table.concat(M.keys(action), " / ")
    end,
  }, function(action)
    picker.select(
      { "Add shortcut", "Replace shortcuts", "Restore defaults" },
      { prompt = action.label },
      function(choice)
        if choice == "Restore defaults" then
          return M.save(action, nil)
        end
        vim.ui.input({ prompt = "Shortcut (example: <leader>xf or <F6>): " }, function(key)
          if not key then
            return
          end
          local valid, message = M.validate(key, action)
          if not valid then
            return vim.notify(message, vim.log.levels.WARN)
          end
          local keys = choice == "Add shortcut" and vim.deepcopy(M.keys(action)) or {}
          if not vim.tbl_contains(keys, key) then
            keys[#keys + 1] = key
          end
          M.save(action, keys)
        end)
      end
    )
  end)
end

return M
