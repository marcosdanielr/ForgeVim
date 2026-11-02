local M = {}

function M.enabled()
  return require("forge.core.config").options.nerd_fonts == true
end

function M.symbol(icon, fallback)
  return M.enabled() and icon or fallback or ""
end

function M.file(buffer)
  if not M.enabled() or vim.env.FORGE_OFFLINE == "1" then
    return "", "ForgeMuted"
  end
  local ok, icons = pcall(require, "nvim-web-devicons")
  if not ok then
    return "", "ForgeMuted"
  end
  local name = vim.fs.basename(vim.api.nvim_buf_get_name(buffer))
  local icon, highlight = icons.get_icon(name, nil, { strict = true })
  if not icon then
    icon, highlight = icons.get_icon_by_filetype(vim.bo[buffer].filetype, { default = true })
  end
  return icon or "", highlight or "ForgeMuted"
end

function M.toggle()
  local state = require("forge.core.state").read()
  local selected = state.nerd_fonts
  if selected == nil then
    selected = M.enabled()
  end
  state.nerd_fonts = not selected
  require("forge.core.state").write(state)
  vim.notify(
    "Nerd Font icons "
      .. (state.nerd_fonts and "enabled" or "disabled")
      .. ". Restart Forge to apply."
  )
end

return M
