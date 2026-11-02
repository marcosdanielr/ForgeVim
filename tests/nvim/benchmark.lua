vim.defer_fn(function()
  vim.o.columns = 140
  vim.o.lines = 45
  require("forge.features.layout").open()
  local jobs = {}
  if vim.env.FORGE_RESOURCE_CASE == "terminals" then
    for _ = 1, 4 do
      jobs[#jobs + 1] = require("forge.features.terminal").new(false).job
      vim.cmd("stopinsert")
    end
  elseif vim.env.FORGE_RESOURCE_CASE == "agents" then
    local tasks = vim.json.decode(table.concat(vim.fn.readfile(vim.env.FORGE_RESOURCE_TASKS), "\n"))
    for _, task in ipairs(tasks) do
      jobs[#jobs + 1] = require("forge.features.agents.chat").launch(task).job
      vim.cmd("stopinsert")
    end
  end
  require("forge.features.panels.windows").focus_editor()
  vim.fn.writefile({ "ready" }, vim.env.FORGE_RESOURCE_READY)
  vim.defer_fn(function()
    for _, job in ipairs(jobs) do
      pcall(vim.fn.jobstop, job)
    end
    vim.wait(5000, function()
      for _, status in ipairs(vim.fn.jobwait(jobs, 0)) do
        if status == -1 then
          return false
        end
      end
      return true
    end)
    vim.cmd("qa!")
  end, tonumber(vim.env.FORGE_RESOURCE_LIFETIME) * 1000)
end, 300)
