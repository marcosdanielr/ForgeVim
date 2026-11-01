local M = {}

local function builtin(name, options)
  options = vim.tbl_extend("force", { cwd = require("forge.core.project").root() }, options or {})
  require("telescope.builtin")[name](options)
end

function M.files()
  builtin("find_files", {
    hidden = true,
    find_command = { "rg", "--files", "--hidden", "-g", "!.git", "-g", "!.forge" },
  })
end

function M.project()
  builtin("live_grep", { additional_args = { "--hidden", "--glob", "!.git", "--glob", "!.forge" } })
end

function M.buffer()
  builtin("current_buffer_fuzzy_find")
end

function M.replace(project)
  local options = { prefills = {}, engine = "ripgrep" }
  if not project then
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
      return vim.notify("Save this buffer before file replacement", vim.log.levels.WARN)
    end
    options.prefills.paths = vim.fn.fnameescape(file)
  end
  options.prefills.flags = "--glob !.forge --glob !.git"
  local root = require("forge.core.project").root()
  require("grug-far").open(options)
  vim.cmd.lcd(vim.fn.fnameescape(root))
end

return M
