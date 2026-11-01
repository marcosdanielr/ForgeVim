local function exercise()
  require("forge.languages.selection").set("python", true)
  require("forge.languages.selection").set("lua", true)
  require("lazy").load({ plugins = { "nvim-lspconfig", "conform.nvim", "nvim-dap" } })
  vim.cmd.edit(vim.env.FORGE_RUNTIME_PROJECT .. "/fixture.py")
  assert(
    vim.wait(15000, function()
      return #vim.lsp.get_clients({ bufnr = 0, name = "pyright" }) > 0
    end),
    "Pyright did not attach"
  )
  local client = vim.lsp.get_clients({ bufnr = 0, name = "pyright" })[1]
  assert(
    vim.wait(15000, function()
      return client.initialized
    end),
    "Pyright did not initialize"
  )
  assert(
    vim.wait(15000, function()
      return #vim.diagnostic.get(0) > 0
    end),
    "No real LSP diagnostic received"
  )
  local response = vim.lsp.buf_request_sync(0, "textDocument/rename", {
    textDocument = { uri = vim.uri_from_bufnr(0) },
    position = { line = 0, character = 2 },
    newName = "greeting",
  }, 5000)
  local rename = response and response[client.id]
  assert(
    rename and rename.result and (rename.result.changes or rename.result.documentChanges),
    "LSP rename did not return edits"
  )
  client:stop(true)
  local dap = require("dap")
  local stopped = false
  dap.listeners.after.event_stopped.runtime_smoke = function()
    stopped = true
  end
  dap.toggle_breakpoint()
  dap.run({
    name = "Runtime smoke",
    type = "python",
    request = "launch",
    program = vim.env.FORGE_RUNTIME_PROJECT .. "/fixture.py",
    cwd = vim.env.FORGE_RUNTIME_PROJECT,
    pythonPath = vim.env.FORGE_RUNTIME_PYTHON,
    console = "internalConsole",
    stopOnEntry = true,
  })
  assert(
    vim.wait(15000, function()
      return stopped
    end),
    "debugpy never stopped"
  )
  assert(dap.session(), "Debug session missing")
  dap.terminate()
  vim.wait(1000, function()
    return dap.session() == nil
  end)
  vim.cmd.edit(vim.env.FORGE_RUNTIME_PROJECT .. "/fixture.lua")
  require("conform").format({ async = false, lsp_format = "never", timeout_ms = 3000 })
  assert(
    vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == "local answer = { value = 42 }",
    "StyLua did not format"
  )
  print("Real Pyright diagnostics/rename, debugpy breakpoint, and StyLua formatting passed")
end
local ok, error = xpcall(exercise, debug.traceback)
if not ok then
  io.stderr:write(error .. "\n")
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
