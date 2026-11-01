local M = {}

local function path()
  return vim.fn.stdpath("state") .. "/forge/preferences.json"
end

function M.read()
  if vim.fn.filereadable(path()) == 0 then
    return { plugins = {}, theme = require("forge.core.config").options.theme }
  end
  local ok, value = pcall(vim.json.decode, table.concat(vim.fn.readfile(path()), "\n"))
  if not ok or type(value) ~= "table" or type(value.plugins) ~= "table" then
    error("Invalid Forge preferences: " .. path())
  end
  return value
end

function M.write(value)
  vim.fn.mkdir(vim.fs.dirname(path()), "p")
  local temporary = path() .. ".tmp"
  vim.fn.writefile({ vim.json.encode(value) }, temporary)
  assert(vim.uv.fs_rename(temporary, path()))
end

return M
