-- Personal tool paths affect only this editor and its child terminals/processes.
local M = {}
local inherited_path = vim.env.PATH

function M.apply()
  local saved = require("forge.core.state").read().tool_paths
  local paths = saved or require("forge.core.config").options.tool_paths
  vim.env.PATH = inherited_path
  for index = #paths, 1, -1 do
    if vim.fn.isdirectory(paths[index]) == 1 then
      vim.env.PATH = paths[index] .. ":" .. vim.env.PATH
    end
  end
end

function M.add()
  vim.ui.input({ prompt = "SDK/tool bin directory: ", completion = "dir" }, function(input)
    if not input then
      return
    end
    local path = vim.fn.fnamemodify(vim.fn.expand(input), ":p"):gsub("/$", "")
    if path:find("[:\r\n]") or vim.fn.isdirectory(path) == 0 then
      return vim.notify(
        "Choose an existing bin directory without a PATH separator",
        vim.log.levels.WARN
      )
    end
    local state = require("forge.core.state").read()
    state.tool_paths = state.tool_paths
      or vim.deepcopy(require("forge.core.config").options.tool_paths)
    if not vim.tbl_contains(state.tool_paths, path) then
      state.tool_paths[#state.tool_paths + 1] = path
    end
    require("forge.core.state").write(state)
    M.apply()
    vim.notify("Tool path saved for Forge. Restart to refresh language servers.")
  end)
end

return M
