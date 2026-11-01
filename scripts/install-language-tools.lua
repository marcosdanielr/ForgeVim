-- Explicit headless maintenance helper; never invoked by normal startup.
local registry = require("mason-registry")
local profiles = require("forge.languages.profiles")
local selection = require("forge.languages.selection")
local pending, failed = {}, {}
local ready = false
registry.refresh(function()
  vim.schedule(function()
    local names = {}
    for name, profile in pairs(profiles) do
      if selection.enabled(name) then
        for _, tool in ipairs(profile.tools) do
          names[tool] = true
        end
      end
    end
    for name in pairs(names) do
      local ok, package = pcall(registry.get_package, name)
      if not ok then
        failed[#failed + 1] = name .. ": registry entry missing"
      elseif not package:is_installed() then
        pending[name] = package
        if not package:is_installing() then
          package:install()
        end
      end
    end
    ready = true
  end)
end)
local completed = vim.wait(900000, function()
  if not ready then
    return false
  end
  for name, package in pairs(pending) do
    if package:is_installed() then
      print("Installed " .. name)
      pending[name] = nil
    elseif not package:is_installing() then
      failed[#failed + 1] = name .. ": installation failed; inspect Mason log"
      pending[name] = nil
    end
  end
  return next(pending) == nil
end, 200)
if not completed then
  failed[#failed + 1] = "Installation timed out; downloads may be retried explicitly"
end
if #failed > 0 then
  for _, message in ipairs(failed) do
    io.stderr:write(message .. "\n")
  end
  vim.cmd("cquit 1")
else
  print("All enabled profile tools are installed")
  vim.cmd("qa!")
end
