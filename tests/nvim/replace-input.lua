local result = vim.env.FORGE_INPUT_RESULT
local form, dialog, stage, previous
local file = vim.fn.getcwd() .. "/example.txt"
local function contents()
  return table.concat(vim.fn.readfile(file), "\n")
end
local function signal(phase, index)
  if index then
    local pane = dialog.windows.actions
    local config = vim.api.nvim_win_get_config(pane.window)
    vim.fn.writefile({
      vim.json.encode({
        phase = phase,
        row = config.row + 2,
        column = config.col + pane.ranges[index].first + 4,
      }),
    }, result)
  else
    vim.fn.writefile({ phase }, result)
  end
  stage = phase
end
vim.defer_fn(function()
  vim.fn.writefile({ "needle needle", "other needle" }, file)
  vim.cmd.edit(file)
  form = {
    root = vim.fn.getcwd(),
    file = file,
    project = false,
    search = "",
    replacement = "",
    regex = false,
    match_case = false,
  }
  stage = "open_find"
  signal("open_find")
end, 150)
local timer = vim.uv.new_timer()
timer:start(
  200,
  30,
  vim.schedule_wrap(function()
    local ok, error = xpcall(function()
      if stage == "open_find" then
        dialog = require("forge.features.search.picker").current()
        if not dialog then
          return
        end
        form = dialog.form
        stage = "opening"
      end
      if not dialog then
        return
      end
      if
        stage == "opening"
        and form.ready
        and vim.fn.mode() == "i"
        and vim.bo.filetype == "forge-replace-search"
      then
        signal("find")
      elseif
        stage == "find"
        and form.search == "needle"
        and form.ready
        and #form.rows == 3
        and vim.bo.filetype == "forge-replace-replacement"
        and vim.fn.mode() == "i"
      then
        assert(
          vim.api.nvim_win_is_valid(dialog.windows.search.window),
          "Changing fields closed search"
        )
        signal("replacement")
      elseif
        stage == "replacement"
        and form.replacement == "done"
        and vim.bo.filetype == "forge-replace-options"
      then
        assert(dialog.option == 1)
        signal("option_case")
      elseif stage == "option_case" and form.ready and form.match_case and dialog.option == 2 then
        signal("option_word")
      elseif stage == "option_word" and form.ready and form.whole_word and dialog.option == 3 then
        signal("option_regex")
      elseif stage == "option_regex" and form.ready and form.regex and dialog.option == 4 then
        signal("option_scope")
      elseif
        stage == "option_scope"
        and form.ready
        and form.project
        and vim.bo.filetype == "forge-replace-results"
      then
        assert(#form.rows == 3)
        signal("next_result")
      elseif stage == "next_result" and dialog.selected == 2 then
        assert(not dialog.closed and contents() == "needle needle\nother needle")
        signal("previous_result")
      elseif
        stage == "previous_result"
        and dialog.selected == 1
        and vim.bo.filetype == "forge-replace-actions"
      then
        assert(
          vim.api.nvim_win_get_cursor(dialog.editor)[2] == 0,
          "Previous did not reveal the source match"
        )
        signal("next_button")
      elseif stage == "next_button" and dialog.selected == 2 then
        signal("previous_button")
      elseif stage == "previous_button" and dialog.selected == 1 then
        signal("replace_first")
      elseif
        stage == "replace_first"
        and form.ready
        and contents() == "done needle\nother needle"
      then
        assert(
          not dialog.closed and dialog.action == 3,
          "Replace closed the dialog or lost its button"
        )
        signal("one")
      elseif stage == "one" and form.ready and contents() == "done done\nother needle" then
        signal("all")
      elseif stage == "all" and dialog.confirming then
        signal("cancel")
      elseif stage == "cancel" and not dialog.confirming then
        assert(contents() == "done done\nother needle", "Cancel changed files")
        signal("all_again")
      elseif stage == "all_again" and dialog.confirming then
        signal("confirm")
      elseif stage == "confirm" and form.ready and #form.rows == 0 then
        assert(contents() == "done done\nother done")
        form.match_case, form.whole_word, form.regex, form.project = false, false, false, false
        vim.fn.writefile({ "á needle needle", "NEEDLE" }, file)
        dialog:search()
        dialog:focus("replacement")
        stage = "mouse_ready"
      elseif stage == "mouse_ready" and form.ready and #form.rows == 3 and vim.fn.mode() == "i" then
        signal("mouse_one", 3)
      elseif stage == "mouse_one" and form.ready and contents() == "á done needle\nNEEDLE" then
        signal("mouse_all", 4)
      elseif stage == "mouse_all" and dialog.confirming then
        signal("mouse_confirm", 1)
      elseif stage == "mouse_confirm" and form.ready and #form.rows == 0 then
        assert(contents() == "á done done\ndone")
        previous = dialog
        signal("resize")
      elseif stage == "resize" and previous.closed then
        dialog = require("forge.features.search.picker").current()
        assert(dialog and dialog.windows.width == 74, "Resize lost the replacement dialog")
        assert(dialog.form.search == "needle" and dialog.form.replacement == "done")
        dialog:close()
        assert(not require("forge.features.search.picker").current())
        timer:stop()
        timer:close()
        signal("passed")
        vim.cmd("qa!")
      end
    end, debug.traceback)
    if not ok then
      timer:stop()
      timer:close()
      vim.fn.writefile({ error }, result)
      vim.cmd("cq")
    end
  end)
)
