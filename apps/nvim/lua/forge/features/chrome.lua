local M = {}

function M.refresh()
  local root = require("forge.core.project").root()
  local tab = vim.api.nvim_get_current_tabpage()
  if vim.t.forge_chrome_root == root then
    return
  end
  vim.t.forge_chrome_root = root
  vim.t.forge_chrome_project = vim.fs.basename(root)
  vim.t.forge_chrome_branch = ""
  require("forge.features.workspace.snapshot").load(root, function(snapshot)
    if vim.api.nvim_tabpage_is_valid(tab) and vim.t[tab].forge_chrome_root == root then
      vim.t[tab].forge_chrome_branch = snapshot.branch
      vim.cmd("redrawtabline")
    end
  end)
end

function M.statusline()
  return require("forge.features.workbench.frame").bottom()
end

function M.tabline()
  local project = (vim.t.forge_chrome_project or "Workspace"):gsub("%%", "%%%%")
  local branch = (vim.t.forge_chrome_branch or ""):gsub("%%", "%%%%")
  local pages = ""
  if #vim.api.nvim_list_tabpages() > 1 then
    for index, tab in ipairs(vim.api.nvim_list_tabpages()) do
      pages = pages .. "%" .. index .. "T [" .. index .. "] %T"
    end
  end
  local count = vim.t.forge_active_agent_count or 0
  return "%#ForgeBadge#  FORGE  %#ForgeSurface#   ◇ Workbench   %#ForgeBorder#│%#ForgeSurface#  "
    .. project
    .. "  "
    .. branch
    .. "   %#ForgeBorder#│%#ForgeAccent#  "
    .. count
    .. " active agents"
    .. "%=%#ForgeMuted#"
    .. pages
    .. " F1 Help   ·   Space Space Commands  "
end

function M.setup()
  require("forge.features.workbench.palette").setup()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("ForgeWorkbenchColors", { clear = true }),
    callback = function()
      require("forge.features.workbench.palette").setup()
    end,
  })
  vim.opt.showtabline = 2
  vim.opt.tabline = "%!v:lua.require('forge.features.chrome').tabline()"
  vim.opt.laststatus = 2
  vim.opt.statusline = "%!v:lua.require('forge.features.chrome').statusline()"
  require("forge.features.workbench.frame").setup()
  vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged", "TabEnter" }, {
    group = vim.api.nvim_create_augroup("ForgeWorkbenchContext", { clear = true }),
    callback = function()
      vim.schedule(M.refresh)
    end,
  })
  vim.schedule(M.refresh)
end

return M
