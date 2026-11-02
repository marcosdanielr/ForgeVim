local M = {}
local forms = {}
local function checked(value)
  return value and "[x]" or "[ ]"
end

local function render(form)
  require("forge.features.panels.text").write(form.buffer, {
    "",
    "  SEARCH & REPLACE",
    "",
    "  Search: " .. (form.search ~= "" and form.search or "(enter text)"),
    "  Replace: " .. (form.replacement ~= "" and form.replacement or "(empty deletes matches)"),
    "",
    "  Scope: " .. (form.project and "Project" or "Current file"),
    "  " .. checked(form.match_case) .. " Match case (Aa)",
    "  " .. checked(form.whole_word) .. " Whole word (ab)",
    "  " .. checked(form.regex) .. " Regular expression (.*)",
    "",
    "  [ Preview matches ]",
    "",
    "  Enter or double-click edits / toggles.",
    "  f Search  r Replace  p Preview  q Hide",
    "",
    "  No files change when opening preview.",
  })
end

local function input(form, field, label)
  vim.ui.input({ prompt = label .. ": ", default = form[field] }, function(value)
    if value ~= nil then
      form[field] = value
      render(form)
    end
  end)
end

function M.preview(form)
  if form.search == "" then
    return vim.notify("Enter search text before previewing", vim.log.levels.INFO)
  end
  if not form.project and (form.file == "" or vim.fn.filereadable(form.file) == 0) then
    return vim.notify("Open and save a file before choosing Current file", vim.log.levels.WARN)
  end
  local prefills = {
    search = form.search,
    replacement = form.replacement,
    flags = table.concat(require("forge.features.search.options").flags(form), " "),
  }
  if not form.project then
    prefills.paths = vim.fn.fnameescape(form.file)
  end
  require("forge.features.panels.windows").hide("search")
  require("forge.features.panels.windows").focus_editor()
  require("grug-far").open({ engine = "ripgrep", prefills = prefills })
  vim.cmd.lcd(vim.fn.fnameescape(form.root))
  vim.notify("Preview first. grug-far: g? shows keys; local leader then r applies replacements.")
end

function M.open(project)
  local windows = require("forge.features.panels.windows")
  local tab = vim.api.nvim_get_current_tabpage()
  local root = require("forge.core.project").root()
  local editor = windows.editor()
  local file = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(editor))
  local form = forms[tab]
  if not form or form.root ~= root then
    form = {
      root = root,
      file = file,
      project = project,
      search = "",
      replacement = "",
      match_case = false,
      whole_word = false,
      regex = false,
    }
    form.buffer = require("forge.features.panels.text").create("Search", root, "forge-search")
    forms[tab] = form
    local function activate()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      if row == 4 then
        input(form, "search", "Search")
      elseif row == 5 then
        input(form, "replacement", "Replace with")
      elseif row == 7 then
        form.project = not form.project
        render(form)
      elseif row == 8 then
        form.match_case = not form.match_case
        render(form)
      elseif row == 9 then
        form.whole_word = not form.whole_word
        render(form)
      elseif row == 10 then
        form.regex = not form.regex
        render(form)
      elseif row == 12 then
        M.preview(form)
      end
    end
    for _, key in ipairs({ "<CR>", "<Space>", "<2-LeftMouse>" }) do
      vim.keymap.set("n", key, activate, { buffer = form.buffer, desc = "Edit search option" })
    end
    vim.keymap.set("n", "f", function()
      input(form, "search", "Search")
    end, { buffer = form.buffer, desc = "Search text" })
    vim.keymap.set("n", "r", function()
      input(form, "replacement", "Replace with")
    end, { buffer = form.buffer, desc = "Replacement text" })
    vim.keymap.set("n", "p", function()
      M.preview(form)
    end, { buffer = form.buffer, desc = "Preview matches" })
    vim.keymap.set("n", "q", function()
      windows.hide("search")
    end, { buffer = form.buffer, desc = "Hide search" })
  end
  form.file, form.project = file, project
  render(form)
  local window = windows.show(
    "search",
    form.buffer,
    { position = "left", size = 42, title = "Search  /  Aa  ab  .*" }
  )
  vim.api.nvim_win_set_cursor(window, { 4, 2 })
  return form
end

return M
