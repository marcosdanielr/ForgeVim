local M = {}

function M.root()
  if type(vim.b.forge_root) == "string" then
    return vim.b.forge_root
  end
  local name = vim.api.nvim_buf_get_name(0)
  local start = name ~= "" and (vim.fn.isdirectory(name) == 1 and name or vim.fs.dirname(name))
    or vim.fn.getcwd()
  return vim.fs.root(start, { ".git" }) or vim.fn.getcwd()
end

-- Agent tabs run inside a task worktree; new agents must target the original checkout.
function M.origin()
  return vim.t.forge_origin or M.root()
end

return M
