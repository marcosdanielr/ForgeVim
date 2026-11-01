local M = {}

function M.root()
  local name = vim.api.nvim_buf_get_name(0)
  local start = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
  return vim.fs.root(start, { ".git" }) or vim.fn.getcwd()
end

return M
