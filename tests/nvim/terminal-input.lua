local windows = require("forge.features.panels.windows")
local first, second, divider, resized_window
local stage = 0
local function record(value)
  vim.fn.writefile({ tostring(value) }, vim.env.FORGE_INPUT_RESULT)
end
local timer = vim.uv.new_timer()
timer:start(
  100,
  100,
  vim.schedule_wrap(function()
    local ok, failure = xpcall(function()
      local panel = windows.get("terminal")
      if stage == 0 then
        assert(#vim.api.nvim_list_uis() == 1, "Terminal input test needs a real TUI")
        stage = 1
        record("ready")
      elseif stage == 1 and panel and vim.bo[panel.buffer].buftype == "terminal" then
        first = panel.buffer
        stage = 2
        record("opened")
      elseif stage == 2 and panel and panel.buffer ~= first then
        second = panel.buffer
        assert(
          vim.fn.jobwait({ vim.b[first].terminal_job_id }, 0)[1] == -1,
          "New terminal killed the first shell"
        )
        assert(vim.w[panel.window].forge_panel_title:find("2/2", 1, true), "Terminal count missing")
        stage = 3
        record("multiple")
      elseif stage == 3 and vim.fn.filereadable("typed.txt") == 1 then
        assert(
          vim.fn.readfile("typed.txt")[1] == " pa pc pl pn ot test spaces",
          "Chat/shell text changed"
        )
        assert(not windows.get("agents"), "Typing Leader text opened Agents")
        assert(not windows.get("chat"), "Typing Leader text opened Chat")
        stage = 5
        record("text_preserved")
      elseif stage == 5 and not panel then
        assert(
          vim.fn.jobwait({ vim.b[first].terminal_job_id, vim.b[second].terminal_job_id }, 0)[1]
            == -1,
          "Hide killed a terminal"
        )
        stage = 6
        record("hidden")
      elseif stage == 6 and panel then
        assert(panel.buffer == second, "Toggle lost the active terminal")
        vim.fn.jobstop(vim.b[first].terminal_job_id)
        vim.fn.jobstop(vim.b[second].terminal_job_id)
        vim.cmd("stopinsert")
        windows.focus_editor()
        vim.cmd("only")
        vim.o.splitright = true
        vim.cmd("vsplit")
        resized_window = vim.api.nvim_get_current_win()
        divider = vim.api.nvim_win_get_position(resized_window)[2]
        stage = 7
        record("resize_left")
      elseif stage == 7 and vim.api.nvim_win_get_position(resized_window)[2] == divider - 3 then
        stage = 8
        record("resize_right")
      elseif stage == 8 and vim.api.nvim_win_get_position(resized_window)[2] == divider then
        vim.cmd("only")
        vim.o.splitbelow = true
        vim.cmd("split")
        resized_window = vim.api.nvim_get_current_win()
        divider = vim.api.nvim_win_get_position(resized_window)[1]
        stage = 9
        record("resize_up")
      elseif stage == 9 and vim.api.nvim_win_get_position(resized_window)[1] == divider - 2 then
        stage = 10
        record("resize_down")
      elseif stage == 10 and vim.api.nvim_win_get_position(resized_window)[1] == divider then
        timer:stop()
        timer:close()
        record("passed")
        vim.cmd("qa!")
      end
    end, debug.traceback)
    if not ok then
      timer:stop()
      timer:close()
      record("error: " .. failure)
      vim.cmd("cquit 1")
    end
  end)
)
