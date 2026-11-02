local ok, failure = xpcall(function()
  require("lazy").install({ wait = true, lockfile = true, show = false })
  require("lazy").restore({ wait = true, show = false })
  for name, plugin in pairs(require("lazy.core.config").plugins) do
    assert(plugin._.installed, "Plugin not installed: " .. name)
    assert(not plugin._.build, "Plugin build unfinished: " .. name)
  end
end, debug.traceback)
if ok then
  vim.cmd("qa!")
else
  io.stderr:write(failure .. "\n")
  vim.cmd("cquit 1")
end
