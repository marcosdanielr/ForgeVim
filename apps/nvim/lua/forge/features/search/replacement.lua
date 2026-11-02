-- Apply verified byte ranges from ripgrep; never re-interpret replacement text as code.
local M = {}

local function prepare(records)
  local files = {}
  for _, record in ipairs(records) do
    local file = files[record.filename]
    if not file then
      local buffer = vim.fn.bufadd(record.filename)
      if vim.bo[buffer].modified then
        error("Save pending edits before replacing: " .. record.filename)
      end
      if vim.fn.filewritable(record.filename) ~= 1 then
        error("File is not writable: " .. record.filename)
      end
      vim.fn.bufload(buffer)
      vim.api.nvim_buf_call(buffer, function()
        vim.cmd("checktime")
      end)
      if vim.bo[buffer].modified then
        error("File has unsaved edits: " .. record.filename)
      end
      file = { buffer = buffer, records = {} }
      files[record.filename] = file
    end
    local actual = vim.api.nvim_buf_get_lines(file.buffer, record.lnum - 1, record.lnum, false)[1]
    if actual ~= record.text then
      error("Search result changed; search again: " .. record.filename)
    end
    file.records[#file.records + 1] = record
  end
  return files
end

function M.apply(records, replacement, all)
  assert(not replacement:find("[\r\n]"), "Replacement must be a single line")
  local files = prepare(records) -- Validate every target before changing any buffer.
  local count = 0
  for _, file in pairs(files) do
    table.sort(file.records, function(left, right)
      if left.lnum ~= right.lnum then
        return left.lnum > right.lnum
      end
      return left.matches[1].start > right.matches[1].start
    end)
    local changed = false
    for _, record in ipairs(file.records) do
      local matches = all and record.matches or { record.matches[1] }
      for index = #matches, 1, -1 do
        local match = matches[index]
        if changed then
          vim.api.nvim_buf_call(file.buffer, function()
            vim.cmd("undojoin")
          end)
        end
        vim.api.nvim_buf_set_text(
          file.buffer,
          record.lnum - 1,
          match.start,
          record.lnum - 1,
          match["end"],
          { replacement }
        )
        changed = true
        count = count + 1
      end
    end
    vim.api.nvim_buf_call(file.buffer, function()
      vim.cmd("silent update")
    end)
  end
  return count
end

return M
