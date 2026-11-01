local function exercise()
  require("forge.features.git").conflicts()
  assert(
    vim.wait(8000, function()
      local view = require("diffview.lib").get_current_view()
      if not view or not view.cur_layout then
        return false
      end
      local window = view.cur_layout:get_main_win()
      if not window:is_valid() then
        return false
      end
      for _, line in
        ipairs(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(window.id), 0, -1, false))
      do
        if line:match("^<<<<<<<") then
          return true
        end
      end
      return false
    end),
    "Merge view did not open"
  )
  local view = require("diffview.lib").get_current_view()
  local main = view.cur_layout:get_main_win()
  vim.api.nvim_set_current_win(main.id)
  local found
  for index, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line:match("^<<<<<<<") then
      found = index
      break
    end
  end
  assert(found, "Conflict result markers not visible")
  vim.api.nvim_win_set_cursor(main.id, { found, 0 })
  require("diffview.actions").conflict_choose("ours")()
  vim.cmd("write")
  local lines = vim.fn.readfile(vim.env.FORGE_GIT_PROJECT .. "/sample.txt")
  assert(lines[1] == "ours" and #lines == 1, "Chosen conflict side was not written")
  vim.cmd("DiffviewClose")
  print("Real three-way merge and explicit conflict selection passed")
end
local ok, error = xpcall(exercise, debug.traceback)
if not ok then
  io.stderr:write(error .. "\n")
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
