local M = {}
local forms = {}

function M.state(project)
  local tab = vim.api.nvim_get_current_tabpage()
  local root = require("forge.core.project").root()
  local editor = require("forge.features.panels.windows").editor()
  local file = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(editor))
  local form = forms[tab]
  if not form or form.root ~= root then
    form = {
      root = root,
      search = "",
      replacement = "",
      match_case = false,
      whole_word = false,
      regex = false,
    }
    forms[tab] = form
  end
  form.file, form.project = file, project
  return form
end

function M.preview(form)
  if not form.project and vim.fn.filereadable(form.file) == 0 then
    return vim.notify("Open and save a file before choosing File scope", vim.log.levels.WARN)
  end
  return require("forge.features.search.picker").open(form)
end

function M.open(project)
  local form = M.state(project)
  M.preview(form)
  return form
end

return M
