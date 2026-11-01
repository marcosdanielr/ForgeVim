local M = {}

function M.setup(directory)
  if vim.env.FORGE_OFFLINE == "1" then
    return
  end
  local path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.uv.fs_stat(path) then
    local result = vim
      .system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        "https://github.com/folke/lazy.nvim.git",
        path,
      }, { text = true })
      :wait()
    if result.code ~= 0 then
      error("Could not install lazy.nvim: " .. (result.stderr or ""))
    end
  end
  vim.opt.rtp:prepend(path)
  local lock = vim.fn.stdpath("state") .. "/forge/lazy-lock.json"
  vim.fn.mkdir(vim.fs.dirname(lock), "p")
  if vim.env.FORGE_UPDATE_LOCK == "1" then
    lock = directory .. "/lazy-lock.json"
  elseif not vim.uv.fs_stat(lock) and vim.uv.fs_stat(directory .. "/lazy-lock.json") then
    vim.fn.writefile(vim.fn.readfile(directory .. "/lazy-lock.json"), lock)
  end
  require("lazy").setup({
    spec = { { import = "forge.plugins" }, require("forge.features.plugins").spec() },
    lockfile = lock,
    defaults = { lazy = true },
    install = { colorscheme = { "habamax" } },
    checker = { enabled = false },
    change_detection = { notify = false },
    performance = {
      rtp = { paths = { directory }, disabled_plugins = { "netrwPlugin", "tutor", "tohtml" } },
    },
  })
  require("forge.features.themes").restore()
end

return M
