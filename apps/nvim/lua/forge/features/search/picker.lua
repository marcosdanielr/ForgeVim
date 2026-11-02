-- A multi-field dialog owns focus; Telescope closes its picker on BufLeave.
local M = {}
local active = {}
local Dialog = {}
Dialog.__index = Dialog

function Dialog:render()
  require("forge.features.search.view").render(self)
  if not self.closed and self.form.ready then
    local entry = self.form.rows[self.selected]
    if entry then
      require("forge.features.search.location").show(self, entry)
    else
      require("forge.features.search.location").clear(self)
    end
  end
end

function Dialog:focus(name, column)
  if self.closed then
    return
  end
  local editable = name == "search" or name == "replacement"
  if not editable then
    vim.cmd("stopinsert")
  end
  local pane = self.windows[name]
  vim.api.nvim_set_current_win(pane.window)
  self.focused = name
  self:render()
  if editable then
    local length = #vim.api.nvim_buf_get_lines(pane.buffer, 0, 1, false)[1]
    vim.api.nvim_win_set_cursor(pane.window, { 1, math.max(0, math.min(column or length, length)) })
    vim.cmd("startinsert!")
  end
end

function Dialog:close()
  if self.closed then
    return
  end
  self.closed = true
  require("forge.features.search.location").clear(self)
  if self.cancel then
    self.cancel()
  end
  if self.timer then
    self.timer:stop()
    self.timer:close()
  end
  if self.group then
    vim.api.nvim_del_augroup_by_id(self.group)
  end
  active[self.tab] = nil
  vim.cmd("stopinsert")
  require("forge.features.search.windows").close(self.windows)
end

function Dialog:resize()
  local form = self.form
  self:close()
  M.open(form)
end

function Dialog:search(anchor)
  self.timer:stop()
  if self.cancel then
    self.cancel()
  end
  self.form.ready = false
  self.form.error = nil
  self.confirming = false
  self:render()
  self.cancel = require("forge.features.search.query").start(
    self.form,
    function(rows, truncated, error)
      if self.closed then
        return
      end
      self.form.rows, self.form.truncated, self.form.error, self.form.ready =
        rows, truncated, error, true
      if anchor then
        self.selected = 1
        for index, entry in ipairs(rows) do
          if
            entry.filename > anchor.filename
            or (
              entry.filename == anchor.filename
              and (
                entry.lnum > anchor.lnum or (entry.lnum == anchor.lnum and entry.col >= anchor.col)
              )
            )
          then
            self.selected = index
            break
          end
        end
      end
      self:render()
    end
  )
end

function Dialog:changed(field)
  if self.closed then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(self.windows[field].buffer, 0, -1, false)
  self.form[field] = table.concat(lines, " ")
  self.confirming = false
  self.message = nil
  self.action = 3
  if field == "search" then
    if self.cancel then
      self.cancel()
    end
    self.form.ready = false
    self.timer:stop()
    self.timer:start(
      100,
      0,
      vim.schedule_wrap(function()
        if not self.closed then
          self:search()
        end
      end)
    )
  end
  vim.schedule(function()
    self:render()
  end)
end

function Dialog:toggle(index)
  if index == 4 and self.form.project and vim.fn.filereadable(self.form.file) == 0 then
    self.message = "Open a saved file before choosing File scope"
    self:render()
    return
  end
  local field = ({ "match_case", "whole_word", "regex", "project" })[index]
  self.form[field] = not self.form[field]
  self.option = index
  self.message = nil
  self:search()
end

function Dialog:apply(all, confirmed)
  if self.confirming and not confirmed then
    return
  end
  if
    all
    and not confirmed
    and self.form.ready
    and not self.form.error
    and not self.form.truncated
    and #self.form.rows > 0
  then
    self.confirming = true
    self.action = 2
    self.message = "Replace all "
      .. #self.form.rows
      .. " occurrences? Choose Confirm replace all or Cancel."
    self:render()
    self:focus("actions")
    return
  end
  local entry = self.form.rows[self.selected]
  local ok, result = require("forge.features.search.actions").apply(self.form, all, entry)
  self.confirming = false
  self.action = 3
  if not ok then
    self.message = tostring(result)
    self:render()
    return
  end
  self.message = "Replaced " .. result .. " · saved"
  local anchor = entry
    and { filename = entry.filename, lnum = entry.lnum, col = entry.col + #self.form.replacement }
  self:search(not all and anchor or nil)
end

function Dialog:activate(index)
  if self.confirming then
    if index == 1 then
      self:apply(true, true)
    else
      self.confirming = false
      self.action = 3
      self.message = "Replace all cancelled"
      self:render()
    end
  elseif index == 1 then
    self:step(-1)
  elseif index == 2 then
    self:step(1)
  elseif index == 3 then
    self:apply(false)
  elseif index == 4 then
    self:apply(true)
  else
    self:close()
  end
end

function Dialog:step(direction)
  if self.confirming or not self.form.ready or #self.form.rows == 0 then
    return
  end
  self.selected = (self.selected - 1 + direction) % #self.form.rows + 1
  self.message = nil
  self:render()
end

function Dialog:open_result()
  local entry = self.form.rows[self.selected]
  if not entry then
    return
  end
  self:close()
  require("forge.features.panels.windows").focus_editor()
  vim.cmd.edit(vim.fn.fnameescape(entry.filename))
  vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col - 1 })
end

function M.current()
  return active[vim.api.nvim_get_current_tabpage()]
end

function M.apply(all)
  local dialog = M.current()
  if not dialog then
    return false
  end
  dialog:apply(all)
  return true
end

function M.open(form)
  local previous = M.current()
  if previous then
    previous:close()
  end
  local windows = require("forge.features.search.windows").open()
  if not windows then
    return
  end
  form.rows, form.ready = {}, false
  local dialog = setmetatable({
    form = form,
    windows = windows,
    tab = vim.api.nvim_get_current_tabpage(),
    selected = 1,
    action = 3,
    focused = "search",
    editor = require("forge.features.panels.windows").editor(),
    option = 1,
    timer = vim.uv.new_timer(),
  }, Dialog)
  active[dialog.tab] = dialog
  for _, field in ipairs({ "search", "replacement" }) do
    vim.api.nvim_buf_set_lines(windows[field].buffer, 0, -1, false, { form[field] })
    vim.api.nvim_buf_attach(windows[field].buffer, false, {
      on_lines = function()
        dialog:changed(field)
      end,
    })
  end
  dialog:render()
  require("forge.features.search.controls").attach(dialog)
  dialog:search()
  dialog:focus("search")
  return dialog
end

return M
