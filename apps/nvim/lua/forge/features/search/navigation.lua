-- Tab follows visual order and visits every checkbox and action separately.
local M = {}

function M.cycle(dialog, direction)
  local targets = {}
  if not dialog.confirming then
    targets = { { "search" }, { "replacement" } }
    for index = 1, 4 do
      targets[#targets + 1] = { "options", index }
    end
    targets[#targets + 1] = { "results" }
  end
  for index = 1, (dialog.confirming and 2 or 5) do
    targets[#targets + 1] = { "actions", index }
  end
  local current = vim.api.nvim_get_current_win()
  local selected = 1
  for index, target in ipairs(targets) do
    local item = target[1] == "options" and dialog.option or dialog.action
    if current == dialog.windows[target[1]].window and (not target[2] or target[2] == item) then
      selected = index
      break
    end
  end
  local target = targets[(selected - 1 + direction) % #targets + 1]
  if target[1] == "options" then
    dialog.option = target[2]
  end
  if target[1] == "actions" then
    dialog.action = target[2]
  end
  dialog:focus(target[1])
end

return M
