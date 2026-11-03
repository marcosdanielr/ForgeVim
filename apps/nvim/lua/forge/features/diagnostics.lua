local M = {}
local choices = {
  { id = "inline", label = "Inline messages beside code" },
  { id = "current_line", label = "Full messages below the current line" },
  { id = "quiet", label = "Signs and underlines only; gl opens details" },
}

local function copy(buffer)
  local message = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
  vim.fn.setreg("+", message)
  vim.fn.setreg('"', message)
  vim.notify("Full diagnostic copied to clipboard")
end

local function controls(buffer, window)
  vim.keymap.set("n", "y", function()
    copy(buffer)
  end, { buffer = buffer, desc = "Copy full diagnostic" })
  vim.keymap.set("n", "<C-c>", function()
    copy(buffer)
  end, { buffer = buffer, desc = "Copy full diagnostic" })
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      if vim.api.nvim_win_is_valid(window) then
        vim.api.nvim_win_close(window, true)
      end
    end, { buffer = buffer, desc = "Close diagnostic details" })
  end
end

function M.setup()
  local selected = require("forge.core.state").read().diagnostic_display
    or require("forge.core.config").options.diagnostic_display
  vim.diagnostic.config({
    severity_sort = true,
    underline = true,
    update_in_insert = false,
    virtual_text = selected == "inline" and { spacing = 2, prefix = "●", source = "if_many" }
      or false,
    virtual_lines = selected == "current_line" and { current_line = true } or false,
    float = { border = "rounded", source = true, header = "Line diagnostics" },
  })
end

function M.open_line()
  local buffer, window = vim.diagnostic.open_float(nil, {
    scope = "line",
    border = "rounded",
    source = true,
    header = " Diagnostic details ",
    focus = true,
    focusable = true,
    max_width = math.max(30, math.floor(vim.o.columns * 0.75)),
  })
  if buffer and window then
    controls(buffer, window)
  end
  return buffer, window
end

function M.choose()
  require("forge.features.picker").select(choices, {
    prompt = "Diagnostic display",
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    local state = require("forge.core.state").read()
    state.diagnostic_display = item.id
    require("forge.core.state").write(state)
    M.setup()
  end)
end

return M
