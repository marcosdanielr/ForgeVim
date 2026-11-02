local M = {}

function M.command(form, query)
  if query == "" then
    return
  end
  local command = { "rg", "--json", "--line-number", "--color", "never" }
  vim.list_extend(command, require("forge.features.search.options").flags(form))
  vim.list_extend(command, { "--", query, form.project and "." or form.file })
  return command
end

function M.entry(root, line)
  local ok, event = pcall(vim.json.decode, line)
  if not ok or event.type ~= "match" or not event.data.path.text or not event.data.lines.text then
    return
  end
  local data = event.data
  local path = data.path.text
  local filename = vim.fs.normalize(path:sub(1, 1) == "/" and path or vim.fs.joinpath(root, path))
  local text = data.lines.text:gsub("[\r\n]+$", "")
  local display = path .. ":" .. data.line_number .. "  " .. text
  return {
    value = { filename = filename, lnum = data.line_number, text = text, matches = data.submatches },
    filename = filename,
    lnum = data.line_number,
    col = data.submatches[1].start + 1,
    display = display,
    ordinal = display,
  }
end

function M.preview(record, replacement, all)
  local text = record.text
  local matches = all and record.matches or { record.matches[1] }
  for index = #matches, 1, -1 do
    local match = matches[index]
    text = text:sub(1, match.start) .. replacement .. text:sub(match["end"] + 1)
  end
  return text
end

return M
