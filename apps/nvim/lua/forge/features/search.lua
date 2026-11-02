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
  require("forge.features.search.form").open(project)
end

return M
