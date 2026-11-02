local function exercise()
  local path = vim.env.FORGE_DART_PROJECT .. "/main.dart"
  vim.cmd.edit(vim.fn.fnameescape(path))
  local buffer = vim.api.nvim_get_current_buf()
  local client = vim.lsp.start({
    name = "forge-real-dart-test",
    cmd = { vim.env.FORGE_DART_BIN, "language-server", "--protocol=lsp" },
    root_dir = vim.env.FORGE_DART_PROJECT,
  })
  assert(client, "Dart language server failed to start")
  assert(
    vim.wait(30000, function()
      return #vim.diagnostic.get(buffer) >= 2
    end, 100),
    "Dart analyzer did not publish errors"
  )
  local messages = {}
  for _, diagnostic in ipairs(vim.diagnostic.get(buffer)) do
    messages[#messages + 1] = diagnostic.message
  end
  local combined = table.concat(messages, "\n")
  assert(combined:find("sdadsa", 1, true), "Missing real undefined-name diagnostic")
  assert(combined:find(";", 1, true), "Missing real semicolon diagnostic")
  vim.api.nvim_win_set_cursor(0, { 2, 3 })
  local popup, window = require("forge.features.diagnostics").open_line()
  assert(popup and window, "Line diagnostic popup did not open")
  local rendered = table.concat(vim.api.nvim_buf_get_lines(popup, 0, -1, false), "\n")
  assert(
    rendered:find("sdadsa", 1, true) and rendered:find(";", 1, true),
    "Popup omitted Dart error messages"
  )
  assert(vim.diagnostic.config().virtual_text, "Inline Dart diagnostics disabled")
  vim.lsp.get_client_by_id(client):stop(true)
  print("Real Dart diagnostics and line popup passed")
end
local ok, failure = xpcall(exercise, debug.traceback)
if not ok then
  io.stderr:write(failure .. "\n")
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
