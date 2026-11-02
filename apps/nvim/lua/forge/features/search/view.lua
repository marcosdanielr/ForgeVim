local M = {}
local namespace = vim.api.nvim_create_namespace("forge-replace")

local function buttons(pane, labels, index, status)
  local text, ranges = "", {}
  for _, label in ipairs(labels) do
    local first = #text
    text = text .. "[ " .. label .. " ]  "
    ranges[#ranges + 1] = { first = first, last = #text - 2 }
  end
  require("forge.features.search.windows").write(pane, status and { text, status } or { text })
  vim.api.nvim_buf_clear_namespace(pane.buffer, namespace, 0, -1)
  local chosen = ranges[index]
  if chosen then
    vim.api.nvim_buf_add_highlight(pane.buffer, namespace, "Visual", 0, chosen.first, chosen.last)
    vim.api.nvim_win_set_cursor(pane.window, { 1, chosen.first })
  end
  pane.ranges = ranges
end

function M.render(dialog)
  if dialog.closed then
    return
  end
  local form, windows = dialog.form, dialog.windows
  local rows, lines = form.rows or {}, {}
  for _, entry in ipairs(rows) do
    local path = vim.fn.fnamemodify(entry.filename, ":.")
    lines[#lines + 1] = string.format("%s:%d:%d  %s", path, entry.lnum, entry.col, entry.value.text)
  end
  if #lines == 0 then
    lines = {
      form.search == "" and "Type in Find to search."
        or (form.ready and "No matches." or "Searching…"),
    }
  end
  require("forge.features.search.windows").write(windows.results, lines)
  vim.api.nvim_win_set_config(windows.results.window, {
    title = " " .. (form.ready and (#rows .. " matches · arrows / j k") or "Searching…") .. " ",
  })
  dialog.selected = math.max(1, math.min(dialog.selected, #rows))
  vim.api.nvim_buf_clear_namespace(windows.results.buffer, namespace, 0, -1)
  if rows[dialog.selected] then
    vim.api.nvim_buf_add_highlight(
      windows.results.buffer,
      namespace,
      "Visual",
      dialog.selected - 1,
      0,
      -1
    )
    vim.api.nvim_win_set_cursor(windows.results.window, { dialog.selected, 0 })
  end
  local preview, entry = { "Select a match to preview its replacement." }, rows[dialog.selected]
  if entry then
    preview = {
      "- " .. entry.value.text,
      "+ "
        .. require("forge.features.search.matches").preview(entry.value, form.replacement, false),
    }
  end
  require("forge.features.search.windows").write(windows.preview, preview)
  vim.bo[windows.preview.buffer].filetype = "diff"
  buttons(windows.options, {
    "Aa " .. (form.match_case and "on" or "off"),
    "Word " .. (form.whole_word and "on" or "off"),
    "Regex " .. (form.regex and "on" or "off"),
    form.project and "Project" or "File",
  }, dialog.option)
  local status = dialog.message or (#rows .. " occurrences · replacement is literal text")
  if not form.ready then
    status = "Searching…"
  end
  if form.truncated then
    status = "2000+ occurrences · refine search before Replace all"
  end
  if form.error then
    status = form.error
  end
  buttons(
    windows.actions,
    dialog.confirming and { "Confirm replace all", "Cancel" }
      or { "Replace one", "Replace all", "Close" },
    dialog.action,
    status
  )
end

return M
