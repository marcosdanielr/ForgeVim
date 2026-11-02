local M = {}

local function is_empty_buffer(buffer)
  return vim.bo[buffer].buftype == ""
    and vim.api.nvim_buf_get_name(buffer) == ""
    and not vim.bo[buffer].modified
    and vim.api.nvim_buf_line_count(buffer) == 1
    and vim.api.nvim_buf_get_lines(buffer, 0, 1, false)[1] == ""
end

function M.open(options)
  options = options or {}
  local root = require("forge.core.project").root()
  local previous_buffer = vim.api.nvim_get_current_buf()
  if is_empty_buffer(previous_buffer) then
    vim.bo[previous_buffer].buflisted = false
  end
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buffer)
  vim.api.nvim_buf_set_name(buffer, "Forge Workspace " .. buffer)
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].filetype = "forge-workspace"
  vim.b[buffer].forge_workspace_dashboard = options.dashboard or nil
  local window = vim.api.nvim_get_current_win()
  local previous = {}
  for _, name in ipairs({ "number", "relativenumber", "signcolumn", "wrap" }) do
    previous[name] = vim.wo[window][name]
  end
  vim.wo[window].number = false
  vim.wo[window].relativenumber = false
  vim.wo[window].signcolumn = "no"
  vim.wo[window].wrap = false
  local snapshot = { branch = "Reading project status...", changed = 0, conflicts = 0 }
  local function redraw()
    require("forge.features.workspace.view").render(buffer, root, snapshot, options.dashboard)
  end
  local function refresh()
    if options.dashboard then
      return
    end
    require("forge.features.workspace.snapshot").load(root, function(updated)
      snapshot = updated
      redraw()
    end)
  end
  local first_row = require("forge.features.workspace.view").render(buffer, root, {
    branch = "Reading project status...",
    changed = 0,
    conflicts = 0,
  }, options.dashboard)
  for _, action in ipairs(require("forge.features.workspace.actions")) do
    vim.keymap.set("n", action.key, "<cmd>" .. action.command .. "<cr>", {
      buffer = buffer,
      desc = action.label,
    })
  end
  local function activate()
    local command = vim.b[buffer].forge_workspace_rows[tostring(vim.api.nvim_win_get_cursor(0)[1])]
    if command then
      vim.cmd(command)
    end
  end
  for _, key in ipairs({ "<CR>", "<2-LeftMouse>" }) do
    vim.keymap.set("n", key, activate, { buffer = buffer, desc = "Open workspace action" })
  end
  vim.keymap.set("n", "R", refresh, { buffer = buffer, desc = "Refresh project status" })
  vim.api.nvim_win_set_cursor(window, { first_row or 1, 2 })
  local group = vim.api.nvim_create_augroup("ForgeWorkspaceBuffer" .. buffer, { clear = true })
  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, { group = group, callback = redraw })
  vim.api.nvim_create_autocmd("BufWinLeave", {
    group = group,
    buffer = buffer,
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(window) then
        for name, value in pairs(previous) do
          vim.wo[window][name] = value
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = buffer,
    once = true,
    callback = function()
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })
  vim.b[buffer].forge_root = root
  if options.dashboard then
    require("forge.features.chrome").refresh(true)
  end
  if not options.dashboard then
    require("forge.features.layout").open()
  end
  refresh()
  return buffer
end

-- The dashboard is intentionally an empty-launch experience. Project workspaces
-- use M.open() so opening a directory never replaces the editor with a welcome UI.
function M.open_dashboard()
  return M.open({ dashboard = true })
end

-- BR-ED-11: welcome only on an empty interactive launch; never replace input files.
function M.setup()
  local stdin = false
  local group = vim.api.nvim_create_augroup("ForgeWorkspace", { clear = true })
  vim.api.nvim_create_autocmd("StdinReadPre", {
    group = group,
    callback = function()
      stdin = true
    end,
  })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    once = true,
    callback = function()
      local saved = require("forge.core.state").read().workspace
      local enabled = saved
      if enabled == nil then
        enabled = require("forge.core.config").options.workspace
      end
      if stdin or #vim.api.nvim_list_uis() == 0 then
        return
      end
      local name = vim.api.nvim_buf_get_name(0)
      if vim.fn.argc() == 1 and vim.fn.isdirectory(name) == 1 then
        vim.cmd.tcd(vim.fn.fnameescape(name))
        vim.cmd("enew")
        vim.schedule(function()
          require("forge.features.layout").open()
        end)
      elseif vim.fn.argc() > 0 and vim.bo.buftype == "" then
        vim.schedule(function()
          require("forge.features.layout").open()
        end)
      elseif not vim.bo.modified and name == "" and vim.bo.buftype == "" then
        if enabled then
          vim.schedule(M.open_dashboard)
        else
          vim.schedule(function()
            require("forge.features.layout").open()
          end)
        end
      end
    end,
  })
end

return M
