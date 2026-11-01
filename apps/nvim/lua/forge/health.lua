local M = {}

function M.check()
  vim.health.start("Forge.nvim")
  for _, tool in ipairs({ "git", "rg", "python3" }) do
    if vim.fn.executable(tool) == 1 then
      vim.health.ok(tool .. " available")
    else
      vim.health.error(tool .. " missing")
    end
  end
  for _, provider in ipairs({ "codex", "claude", "gemini" }) do
    if vim.fn.executable(provider) == 1 then
      vim.health.ok(provider .. " CLI available (authentication is user-managed)")
    else
      vim.health.info(provider .. " CLI not installed (optional provider)")
    end
  end
  vim.health.info("Use :ForgeLanguages for explicit tool installation; :Mason shows status")
  vim.health.info(
    "Shift/Ctrl shortcuts depend on terminal protocol; leader mappings always remain available"
  )
end

return M
