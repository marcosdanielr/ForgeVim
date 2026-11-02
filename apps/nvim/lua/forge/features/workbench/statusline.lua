-- BR-ED-22: one global statusbar; redraw reads cached metadata and native state only.
local M = {}
local files, diagnostics = {}, {}
local modes = {
  n = { "NORMAL", "ForgeModeNormal" },
  i = { "INSERT", "ForgeModeInsert" },
  v = { "VISUAL", "ForgeModeVisual" },
  V = { "V-LINE", "ForgeModeVisual" },
  ["\22"] = { "V-BLOCK", "ForgeModeVisual" },
  c = { "COMMAND", "ForgeModeNormal" },
  t = { "TERMINAL", "ForgeModeInsert" },
  R = { "REPLACE", "ForgeModeReplace" },
}
local function escape(text)
  return text:gsub("%%", "%%%%")
end

function M.refresh(buffer)
  if not vim.api.nvim_buf_is_valid(buffer) then
    return
  end
  local icon, highlight = require("forge.features.workbench.icons").file(buffer)
  files[buffer] = { icon = icon, highlight = highlight }
end

local function count(buffer)
  local counts = { 0, 0, 0, 0 }
  for _, diagnostic in ipairs(vim.diagnostic.get(buffer)) do
    counts[diagnostic.severity] = counts[diagnostic.severity] + 1
  end
  diagnostics[buffer] = counts
  vim.cmd("redrawstatus")
end

local function document()
  local window = vim.api.nvim_get_current_win()
  local buffer = vim.api.nvim_win_get_buf(window)
  if vim.bo[buffer].buftype ~= "" then
    local editor = require("forge.features.panels.windows").state().editor
    if editor and vim.api.nvim_win_is_valid(editor) then
      window = editor
    end
  end
  return window, vim.api.nvim_win_get_buf(window)
end

function M.render()
  local window, buffer = document()
  local current_mode = vim.api.nvim_get_mode().mode
  local mode = modes[current_mode] or modes[current_mode:sub(1, 1)] or modes.n
  local counts = diagnostics[buffer] or { 0, 0, 0, 0 }
  local icons = require("forge.features.workbench.icons")
  local branch = vim.t.forge_chrome_branch or ""
  branch = branch:match("^(.-)%.%.%.") or branch
  local info = files[buffer] or { icon = "", highlight = "ForgeMuted" }
  local cursor = vim.api.nvim_win_get_cursor(window)
  local filetype = vim.bo[buffer].filetype
  if filetype == "forge-workspace" or filetype == "" then
    filetype = "Text"
  end
  local encoding = vim.bo[buffer].fileencoding ~= "" and vim.bo[buffer].fileencoding
    or vim.o.encoding
  local formats = { unix = "LF", dos = "CRLF", mac = "CR" }
  local left = "%#" .. mode[2] .. "# " .. icons.symbol(" ", "") .. mode[1] .. " %#ForgeSurface# "
  if branch ~= "" then
    left = left .. "%#ForgeAccent# " .. icons.symbol("", "Git") .. " " .. escape(branch) .. "  "
  end
  left = left
    .. "%#ForgeError# "
    .. icons.symbol("", "E")
    .. " "
    .. counts[1]
    .. "%#ForgeWarning#  "
    .. icons.symbol("", "W")
    .. " "
    .. counts[2]
    .. "%#ForgeMuted#  "
    .. (vim.bo[buffer].modified and "[+] " or "")
    .. (vim.bo[buffer].readonly and "[RO] " or "")
  local position = string.format("  Ln %d, Col %d  ", cursor[1], cursor[2] + 1)
  if vim.o.columns < 100 then
    return left .. "%=%#ForgeSurface#" .. position
  end
  return left
    .. "%=%#"
    .. info.highlight
    .. "# "
    .. info.icon
    .. "%#ForgeSurface# "
    .. escape(filetype)
    .. "  │  "
    .. escape(encoding:upper())
    .. "  "
    .. (formats[vim.bo[buffer].fileformat] or "LF")
    .. "  │"
    .. position
end

function M.setup()
  local group = vim.api.nvim_create_augroup("ForgeGlobalStatusline", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufFilePost", "FileType" }, {
    group = group,
    callback = function(event)
      M.refresh(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = group,
    callback = function(event)
      count(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(event)
      files[event.buf], diagnostics[event.buf] = nil, nil
    end,
  })
  M.refresh(vim.api.nvim_get_current_buf())
end

return M
