local M = {}
local choices = {
  { id = "inline", label = "Inline messages beside code" },
  { id = "current_line", label = "Full messages below the current line" },
  { id = "quiet", label = "Signs and underlines only; gl opens details" },
}

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
  return vim.diagnostic.open_float(nil, {
    scope = "line",
    border = "rounded",
    source = true,
    header = "Line diagnostics",
    max_width = math.max(30, math.floor(vim.o.columns * 0.75)),
  })
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
