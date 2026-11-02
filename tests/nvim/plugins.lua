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
  local workspace = require("forge.features.workspace").open()
  assert(vim.bo.filetype == "forge-workspace" and not vim.bo.modifiable)
  assert(require("nvim-tree.api").tree.is_visible(), "Workspace file tree did not open")
  vim.fn.maparg("<C-h>", "n", false, true).callback()
  assert(vim.bo.filetype == "NvimTree", "Ctrl H did not focus file tree")
  vim.fn.maparg("<C-l>", "n", false, true).callback()
  assert(vim.api.nvim_get_current_buf() == workspace, "Ctrl L did not restore workspace")
  local path = require("forge").root .. "/README.md"
  local document = vim.fn.bufadd(path)
  vim.fn.bufload(document)
  require("nvim-tree.api").tree.find_file({ buf = document, open = true, focus = true })
  assert(
    vim.wait(3000, function()
      local node = require("nvim-tree.api").tree.get_node_under_cursor()
      return node and node.absolute_path == path
    end),
    "Explorer could not select source file"
  )
  vim.fn.maparg("l", "n", false, true).callback()
  assert(vim.api.nvim_get_current_buf() == document, "Explorer l did not open file in editor")
  require("nvim-tree.api").tree.close()
  require("forge.features.git").history()
  assert(
    vim.wait(5000, function()
      return vim.api.nvim_buf_get_name(0):find("Forge commit graph", 1, true) ~= nil
    end),
    "Commit graph did not open"
  )
  vim.cmd("normal! gg")
  vim.fn.search("%x%x%x%x%x%x%x", "W")
  vim.fn.maparg("<CR>", "n", false, true).callback()
  assert(
    vim.wait(5000, function()
      return require("diffview.lib").get_current_view() ~= nil
    end),
    "Commit graph did not open commit review"
  )
  vim.cmd("DiffviewClose")
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
