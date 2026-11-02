local M = {}

function M.apply(form, all, refresh)
  local state = require("telescope.actions.state")
  if state.get_current_line() ~= form.search then
    return vim.notify("Wait for the current query to finish", vim.log.levels.INFO)
  end
  if not form.ready then
    return vim.notify("Wait for search to finish", vim.log.levels.INFO)
  end
  if form.error then
    return vim.notify(form.error, vim.log.levels.ERROR)
  end
  if all and form.truncated then
    return vim.notify(
      "More than 2000 matching lines. Refine your search before Replace all.",
      vim.log.levels.WARN
    )
  end
  local selected = state.get_selected_entry()
  local entries = all and form.rows or (selected and { selected } or {})
  if #entries == 0 then
    return vim.notify("No matches to replace", vim.log.levels.INFO)
  end
  local records, count = {}, 0
  for _, entry in ipairs(entries) do
    records[#records + 1] = entry.value
    count = count + (all and #entry.value.matches or 1)
  end
  local function replace()
    local ok, result =
      pcall(require("forge.features.search.replacement").apply, records, form.replacement, all)
    if not ok then
      return vim.notify(tostring(result), vim.log.levels.ERROR)
    end
    vim.notify("Replaced " .. result .. " occurrence(s)")
    refresh()
  end
  if all then
    if
      vim.fn.confirm(
        "Replace all "
          .. count
          .. " occurrences in "
          .. (form.project and "project files" or "this file")
          .. "?",
        "&Cancel\n&Replace all",
        1
      ) == 2
    then
      replace()
    end
  else
    replace()
  end
end

return M
