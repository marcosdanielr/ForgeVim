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
  assert(require("forge.features.workbench.icons").enabled(), "Default Nerd Font icons disabled")
  local seen = {}
  for _, extension in ipairs({
    "ts",
    "tsx",
    "js",
    "html",
    "css",
    "dart",
    "go",
    "py",
    "rs",
    "lua",
    "php",
  }) do
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buffer, vim.fn.tempname() .. "." .. extension)
    local icon, highlight = require("forge.features.workbench.icons").file(buffer)
    assert(
      icon ~= "" and highlight:find("DevIcon", 1, true),
      "Missing language icon: " .. extension
    )
    seen[icon] = true
    vim.api.nvim_buf_delete(buffer, { force = true })
  end
  assert(vim.tbl_count(seen) >= 8, "Languages use generic repeated icons")
  local completion = require("blink.cmp.config")
  completion.validate(completion)
  assert(vim.lsp.config.lua_ls.settings.Lua.diagnostics.globals[1] == "vim")
  assert(require("dap").adapters["pwa-node"].type == "server")
  assert(require("dap").configurations.rust[1].type == "codelldb")
  assert(require("conform").formatters_by_ft.python[2] == "black")
  for _, theme in ipairs({ "habamax", "tokyonight", "catppuccin", "rose-pine" }) do
    assert(require("forge.features.themes").apply(theme))
  end
  assert(require("forge.features.themes").apply("tokyonight"))
  local original_editor = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local original_string = vim.api.nvim_get_hl(0, { name = "String", link = false })
  local original_folder = vim.api.nvim_get_hl(0, { name = "NvimTreeFolderIcon", link = false })
  for _ = 1, 2 do
    assert(require("forge.features.themes").apply("forge-mint"))
    assert(vim.g.colors_name == "forge-mint", "Mint theme lost its identity")
    assert(
      vim.api.nvim_get_hl(0, { name = "String", link = false }).fg == 0xa6e3a1,
      "Mint syntax colors missing"
    )
    assert(
      vim.api.nvim_get_hl(0, { name = "@function", link = false }).fg == 0xc1f29d,
      "Mint Tree-sitter colors missing"
    )
    for _, group in ipairs({
      "NvimTreeFolderIcon",
      "NvimTreeOpenedFolderIcon",
      "NvimTreeClosedFolderIcon",
      "NvimTreeFolderName",
      "NvimTreeEmptyFolderName",
      "NvimTreeOpenedFolderName",
    }) do
      assert(
        vim.api.nvim_get_hl(0, { name = group, link = false }).fg == 0x69e598,
        "Mint folder color missing: " .. group
      )
    end
    assert(vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg == 0x050907)
    assert(require("forge.features.themes").apply("tokyonight"))
    assert(
      vim.deep_equal(vim.api.nvim_get_hl(0, { name = "String", link = false }), original_string),
      "Mint syntax leaked into Tokyo Night"
    )
    assert(
      vim.deep_equal(vim.api.nvim_get_hl(0, { name = "Normal", link = false }), original_editor),
      "Mint changed Tokyo Night editor colors"
    )
    assert(
      vim.deep_equal(
        vim.api.nvim_get_hl(0, { name = "NvimTreeFolderIcon", link = false }),
        original_folder
      ),
      "Mint leaked into Tokyo Night folders"
    )
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
  vim.o.columns, vim.o.lines = 190, 58
  require("forge.features.layout").open()
  require("forge.features.git").tree()
  assert(not require("nvim-tree.api").tree.is_visible(), "Tree did not hide")
  require("forge.features.git").tree()
  local tree_window = require("nvim-tree.api").tree.winid()
  local panels = require("forge.features.panels.windows")
  local navigation = assert(panels.get("activity"))
  assert(
    vim.api.nvim_win_get_position(navigation.window)[2]
      < vim.api.nvim_win_get_position(tree_window)[2],
    "Reopening explorer reordered navigation"
  )
  panels.focus_editor()
  assert(vim.api.nvim_get_current_buf() == document, "Reopening explorer replaced source")
  for _, id in ipairs({ "activity", "agents", "chat", "logs", "terminal" }) do
    panels.hide(id)
  end
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
  local fixture = vim.fn.tempname() .. ".txt"
  vim.fn.writefile({ "before needle after" }, fixture)
  require("grug-far").open({
    prefills = {
      search = "needle",
      replacement = "replacement",
      paths = fixture,
      flags = "--fixed-strings --case-sensitive",
    },
  })
  local preview_buffer = vim.api.nvim_get_current_buf()
  assert(
    vim.wait(5000, function()
      return table
        .concat(vim.api.nvim_buf_get_lines(preview_buffer, 0, -1, false), "\n")
        :find("before needle after", 1, true)
    end),
    "Replacement preview did not show matches"
  )
  assert(vim.fn.readfile(fixture)[1] == "before needle after", "Opening preview changed the file")
  require("forge.features.search.preview").apply()
  assert(
    vim.wait(5000, function()
      return vim.fn.readfile(fixture)[1] == "before replacement after"
    end),
    "Explicit apply action did not replace text"
  )
  vim.fn.delete(fixture)
  local search_file = vim.fn.tempname() .. " space.txt"
  vim.fn.writefile({ "needle needle", "other needle" }, search_file)
  local form = {
    root = vim.fs.dirname(search_file),
    file = search_file,
    project = false,
    search = "needle",
    replacement = "done",
    match_case = false,
    regex = false,
  }
  local dialog = require("forge.features.search.form").preview(form)
  assert(
    vim.wait(5000, function()
      return form.ready and #form.rows == 3
    end),
    "Replacement dialog did not list each occurrence"
  )
  assert(vim.fn.readfile(search_file)[1] == "needle needle", "Opening search changed source")
  local prompt = dialog.windows.search.buffer
  local replacement = dialog.windows.replacement.buffer
  dialog:focus("replacement")
  vim.wait(100)
  assert(
    vim.api.nvim_get_current_buf() == replacement and vim.api.nvim_buf_is_valid(prompt),
    "Changing fields closed search"
  )
  require("forge.features.search.picker").apply(false)
  assert(vim.wait(5000, function()
    return form.ready and #form.rows == 2
  end))
  assert(vim.fn.readfile(search_file)[1] == "done needle", "Replace one changed wrong occurrence")
  dialog:apply(true)
  assert(dialog.confirming, "Replace all skipped confirmation")
  dialog:activate(2)
  assert(vim.fn.readfile(search_file)[1] == "done needle", "Cancel changed source")
  dialog:apply(true)
  dialog:activate(1)
  assert(vim.wait(5000, function()
    return form.ready and #form.rows == 0
  end))
  assert(
    table.concat(vim.fn.readfile(search_file), "\n") == "done done\nother done",
    "Replace all missed an occurrence"
  )
  dialog:close()
  vim.fn.delete(search_file)
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
