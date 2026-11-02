local result = assert(vim.env.FORGE_WORKSPACE_RESULT)
local expected = assert(vim.env.FORGE_WORKSPACE_MODE)

vim.defer_fn(function()
  local dashboard = vim.bo.filetype == "forge-workspace"
  if expected == "empty" then
    assert(dashboard, "Empty launch did not open the ForgeVim dashboard")
    assert(#vim.api.nvim_tabpage_list_wins(0) == 1, "Dashboard did not occupy the full screen")
    assert(not require("nvim-tree.api").tree.is_visible(), "Dashboard opened a file tree")
    assert(
      vim.t.forge_chrome_project == "No project open",
      "Dashboard exposed the current repository"
    )
    assert(vim.t.forge_chrome_branch == "", "Dashboard exposed a Git branch")
  else
    assert(not dashboard, "Project launch opened the welcome dashboard")
    assert(vim.fn.getcwd() == expected, "Project directory was not selected")
  end
  vim.fn.writefile({ "passed" }, result)
  vim.cmd("qa!")
end, 400)
