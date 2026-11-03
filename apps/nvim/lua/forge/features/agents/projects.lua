-- Registered Git checkouts whose agents appear together in the Agents panel.
local M = {}

local function saved()
  local list = require("forge.core.state").read().projects
  return type(list) == "table" and list or {}
end

-- The current checkout is always listed; registered projects follow in saved order.
function M.list()
  local current = require("forge.core.project").origin()
  local roots, seen = {}, {}
  for _, root in ipairs(vim.list_extend({ current }, saved())) do
    if not seen[root] and vim.fn.isdirectory(root) == 1 then
      seen[root] = true
      roots[#roots + 1] = root
    end
  end
  return roots
end

function M.name(root)
  return vim.fs.basename(root)
end

function M.add(input)
  local path = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(input), ":p"))
  local root = vim.fs.root(path, ".git")
  if vim.fn.isdirectory(path) == 0 or not root then
    return vim.notify("Not a Git project: " .. path, vim.log.levels.WARN)
  end
  local state = require("forge.core.state").read()
  state.projects = state.projects or {}
  if not vim.tbl_contains(state.projects, root) then
    table.insert(state.projects, root)
    require("forge.core.state").write(state)
  end
  vim.notify("Project added: " .. M.name(root))
  require("forge.features.agents.panel").refresh(true)
end

function M.prompt_add()
  require("forge.features.input").open({
    prompt = "Add project (path to a Git checkout)",
    default = require("forge.core.project").origin(),
  }, M.add)
end

function M.remove(root)
  local state = require("forge.core.state").read()
  state.projects = vim.tbl_filter(function(item)
    return item ~= root
  end, saved())
  require("forge.core.state").write(state)
  vim.notify("Project removed from Forge; files and agents were not touched.")
  require("forge.features.agents.panel").refresh(true)
end

-- Opens a project in its own tab so explorer, buffers, and terminals follow it.
function M.open(root)
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    if vim.t[tab].forge_project == root and not vim.t[tab].forge_agent then
      return vim.api.nvim_set_current_tabpage(tab)
    end
  end
  vim.cmd.tabnew()
  vim.cmd.tcd(vim.fn.fnameescape(root))
  vim.t.forge_project = root
  require("forge.features.workspace").open()
end

return M
