local M = {}

function M.open()
  local root = require("forge.core.project").root()
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buffer)
  vim.api.nvim_buf_set_name(buffer, "Forge Workspace " .. buffer)
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].filetype = "forge-workspace"
  local window = vim.api.nvim_get_current_win()
  local previous = {}
  for _, name in ipairs({ "number", "relativenumber", "signcolumn", "wrap" }) do
    previous[name] = vim.wo[window][name]
  end
  vim.wo[window].number = false
  vim.wo[window].relativenumber = false
  vim.wo[window].signcolumn = "no"
  vim.wo[window].wrap = false
  local function refresh()
    require("forge.features.workspace.snapshot").load(root, function(snapshot)
      require("forge.features.workspace.view").render(buffer, root, snapshot)
    end)
  end
  local first_row = require("forge.features.workspace.view").render(buffer, root, {
    branch = "Reading project status...",
    changed = 0,
    conflicts = 0,
  })
  for _, action in ipairs(require("forge.features.workspace.actions")) do
    vim.keymap.set("n", action.key, "<cmd>" .. action.command .. "<cr>", {
      buffer = buffer,
      desc = action.label,
    })
  end
  vim.keymap.set("n", "<CR>", function()
    local command = vim.b[buffer].forge_workspace_rows[vim.api.nvim_win_get_cursor(0)[1]]
    if command then
      vim.cmd(command)
    end
  end, { buffer = buffer, desc = "Open workspace action" })
  vim.keymap.set("n", "R", refresh, { buffer = buffer, desc = "Refresh project status" })
  vim.api.nvim_win_set_cursor(window, { first_row or 1, 2 })
  if vim.env.FORGE_OFFLINE ~= "1" then
    require("nvim-tree.api").tree.open({ path = root, focus = false })
    vim.api.nvim_set_current_win(window)
  end
  local group = vim.api.nvim_create_augroup("ForgeWorkspaceBuffer" .. buffer, { clear = true })
  vim.api.nvim_create_autocmd("VimResized", { group = group, callback = refresh })
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
  refresh()
  return buffer
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
      if
        not require("forge.core.config").options.workspace
        or stdin
        or vim.fn.argc() > 0
        or #vim.api.nvim_list_uis() == 0
        or vim.bo.modified
        or vim.api.nvim_buf_get_name(0) ~= ""
        or vim.bo.buftype ~= ""
      then
        return
      end
      vim.schedule(M.open)
    end,
  })
end

return M
