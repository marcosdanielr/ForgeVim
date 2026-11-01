local M = {}

M.catalog = {
  { id = "codex", label = "ChatGPT / Codex", executable = "codex", login = { "codex", "login" } },
  {
    id = "claude",
    label = "Claude Code",
    executable = "claude",
    login = { "claude", "auth", "login" },
  },
  { id = "gemini", label = "Gemini CLI", executable = "gemini", login = { "gemini" } },
}

function M.choose(callback)
  require("forge.features.picker").select(M.catalog, {
    prompt = "Agent provider (uses your CLI account)",
    format_item = function(provider)
      local installed = vim.fn.executable(provider.executable) == 1
      return provider.label .. (installed and "" or " [CLI not installed]")
    end,
  }, function(provider)
    if vim.fn.executable(provider.executable) == 0 then
      return vim.notify(
        "Install " .. provider.executable .. " CLI first; see docs/providers.md",
        vim.log.levels.WARN
      )
    end
    callback(provider)
  end)
end

function M.connect()
  M.choose(function(provider)
    vim.cmd("botright new")
    vim.fn.jobstart(provider.login, { term = true })
    vim.cmd("startinsert")
  end)
end

return M
