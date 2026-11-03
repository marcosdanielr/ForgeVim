local M = {}

local choices = {
  { label = "1  Left of editor", position = "left" },
  { label = "2  Right of editor", position = "right" },
  { label = "3  Below editor", position = "below" },
  { label = "4  Above editor", position = "above" },
}

function M.choose()
  local window = vim.api.nvim_get_current_win()
  local id = vim.w[window].forge_panel_id
  if not id then
    return vim.notify("Focus a Forge panel before moving it", vim.log.levels.WARN)
  end
  vim.ui.select(choices, {
    prompt = "Move " .. (vim.w[window].forge_panel_title or id),
    format_item = function(choice)
      return choice.label
    end,
  }, function(choice)
    if choice then
      require("forge.features.panels.windows").move(id, choice.position)
    end
  end)
end

return M
