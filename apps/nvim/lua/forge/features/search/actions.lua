local M = {}

function M.apply(form, all, selected)
  if not form.ready then
    return false, "Wait for search to finish"
  end
  if form.error then
    return false, form.error
  end
  if all and form.truncated then
    return false, "Refine search before Replace all (2000+ occurrences)"
  end
  local entries = all and form.rows or (selected and { selected } or {})
  if #entries == 0 then
    return false, "No matches to replace"
  end
  local records = {}
  for _, entry in ipairs(entries) do
    records[#records + 1] = entry.value
  end
  return pcall(require("forge.features.search.replacement").apply, records, form.replacement, all)
end

return M
