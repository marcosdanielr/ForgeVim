-- Each session retains its terminal buffer and owned Neovim job across hide/show.
local M = {}

function M.launch(arguments, options)
  local windows = require("forge.features.panels.windows")
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[buffer].bufhidden = "hide"
  local window = windows.show(options.slot, buffer, options)
  local session =
    { buffer = buffer, root = options.root, slot = options.slot, title = options.title }
  vim.api.nvim_win_call(window, function()
    session.job = vim.fn.jobstart(arguments, {
      term = true,
      cwd = options.cwd or options.root,
      env = options.env,
      on_exit = function(_, code)
        session.exit_code = code
        if options.on_exit then
          vim.schedule(function()
            options.on_exit(code, session)
          end)
        end
      end,
    })
  end)
  if session.job <= 0 then
    windows.hide(options.slot)
    vim.api.nvim_buf_delete(buffer, { force = true })
    error("Could not start " .. options.title)
  end
  vim.bo[buffer].buflisted = false
  vim.b[buffer].forge_root = options.root
  vim.b[buffer].forge_terminal_slot = options.slot
  vim.cmd("startinsert")
  return session
end

function M.show(session, options)
  if not session or not vim.api.nvim_buf_is_valid(session.buffer) then
    return false
  end
  options = vim.tbl_extend("force", options or {}, { title = session.title })
  require("forge.features.panels.windows").show(session.slot, session.buffer, options)
  if session.exit_code == nil then
    vim.cmd("startinsert")
  end
  return true
end

return M
