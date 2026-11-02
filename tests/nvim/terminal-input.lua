local windows = require("forge.features.panels.windows")
local first, second
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
        assert(vim.fn.maparg("<C-Space>", "i") == "", "Terminal key replaced insert completion")
        vim.fn.jobstop(vim.b[first].terminal_job_id)
        vim.fn.jobstop(vim.b[second].terminal_job_id)
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
