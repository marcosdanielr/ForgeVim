local errors = {}
local notify = vim.notify
vim.notify = function(message, level, options)
  if level == vim.log.levels.ERROR then
    errors[#errors + 1] = tostring(message)
  end
  notify(message, level, options)
end

local function exercise()
  require("lazy").load({
    plugins = {
      "blink.cmp",
      "nvim-lspconfig",
      "conform.nvim",
      "nvim-dap",
      "telescope.nvim",
      "grug-far.nvim",
      "neogit",
      "diffview.nvim",
      "nvim-tree.lua",
    },
  })
  vim.wait(100)
  assert(#errors == 0, table.concat(errors, "\n"))
  local completion = require("blink.cmp.config")
  completion.validate(completion)
  assert(vim.lsp.config.lua_ls.settings.Lua.diagnostics.globals[1] == "vim")
  assert(require("dap").adapters["pwa-node"].type == "server")
  assert(require("dap").configurations.rust[1].type == "codelldb")
  assert(require("conform").formatters_by_ft.python[2] == "black")
  for _, theme in ipairs({ "habamax", "tokyonight", "catppuccin", "rose-pine" }) do
    assert(require("forge.features.themes").apply(theme))
  end
  require("forge.features.git").tree()
  assert(require("nvim-tree.api").tree.is_visible(), "File tree did not open")
  require("nvim-tree.api").tree.close()
  require("forge.features.git").diff()
  vim.wait(100)
  assert(require("diffview.lib").get_current_view(), "Diffview did not open")
  vim.cmd("DiffviewClose")
  require("forge.features.git").status()
  vim.wait(200)
  assert(vim.bo.filetype == "NeogitStatus", "Neogit status did not open")
  vim.cmd("tabnew")
  require("telescope").load_extension("ui-select")
  require("grug-far").open({ prefills = { search = "fixture" } })
  vim.wait(200)
  assert(#errors == 0, table.concat(errors, "\n"))
end

local ok, error = xpcall(exercise, debug.traceback)
if not ok then
  io.stderr:write(error .. "\n")
  vim.cmd("cquit 1")
else
  print("Installed plugin integration passed")
  vim.cmd("qa!")
end
