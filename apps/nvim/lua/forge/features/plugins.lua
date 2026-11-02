local M = {}
local catalog = {
  { repository = "zbirenbaum/copilot.lua", label = "Copilot inline completion", default = false },
  { repository = "lewis6991/gitsigns.nvim", label = "Git signs and hunks", default = true },
  { repository = "folke/which-key.nvim", label = "Discover leader shortcuts", default = true },
}

function M.enabled(repository, default)
  local value = require("forge.core.state").read().plugins[repository]
  if value == nil then
    return default
  end
  return value
end

function M.spec()
  local result = vim.deepcopy(require("forge.core.config").options.plugin_specs or {})
  for repository, enabled in pairs(require("forge.core.state").read().plugins) do
    local known = false
    for _, item in ipairs(catalog) do
      known = known or item.repository == repository
    end
    if not known and repository:match("^[%w_.-]+/[%w_.-]+$") then
      result[#result + 1] = { repository, enabled = enabled, lazy = false }
    end
  end
  return result
end

local function persist(repository, enabled)
  local state = require("forge.core.state").read()
  state.plugins[repository] = enabled
  require("forge.core.state").write(state)
  vim.notify("Saved plugin choice. Restart Forge to install or unload; :Lazy shows progress.")
end

function M.choose()
  local items = { "Manage installed plugins (:Lazy)", "Add GitHub plugin (owner/repository)" }
  for _, item in ipairs(catalog) do
    local default = item.default
    if item.repository == "zbirenbaum/copilot.lua" then
      default = require("forge.core.config").options.copilot
    end
    items[#items + 1] = (M.enabled(item.repository, default) and "[on] " or "[off] ") .. item.label
  end
  local extras = {}
  for repository in pairs(require("forge.core.state").read().plugins) do
    local known = false
    for _, item in ipairs(catalog) do
      known = known or item.repository == repository
    end
    if not known then
      extras[#extras + 1] = repository
    end
  end
  table.sort(extras)
  for _, repository in ipairs(extras) do
    items[#items + 1] = (M.enabled(repository, false) and "[on] " or "[off] ") .. repository
  end
  require("forge.features.picker").select(items, { prompt = "Plugins" }, function(choice)
    if choice == items[1] then
      vim.cmd("Lazy")
    elseif choice == items[2] then
      vim.ui.input({ prompt = "Trusted GitHub plugin (owner/repository): " }, function(repository)
        if not repository then
          return
        end
        if not repository:match("^[%w_.-]+/[%w_.-]+$") then
          return vim.notify("Use owner/repository", vim.log.levels.ERROR)
        end
        persist(repository, true)
      end)
    else
      for index, item in ipairs(catalog) do
        if choice == items[index + 2] then
          local default = item.repository == "zbirenbaum/copilot.lua"
              and require("forge.core.config").options.copilot
            or item.default
          return persist(item.repository, not M.enabled(item.repository, default))
        end
      end
      for index, repository in ipairs(extras) do
        if choice == items[#catalog + index + 2] then
          return persist(repository, not M.enabled(repository, false))
        end
      end
    end
  end)
end

return M
