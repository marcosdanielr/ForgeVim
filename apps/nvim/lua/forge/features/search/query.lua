-- One cancellable ripgrep request; every result represents exactly one occurrence.
local M = {}

function M.start(form, done)
  local command = require("forge.features.search.matches").command(form, form.search)
  local cancelled, process = false, nil
  local rows, pending, truncated = {}, "", false
  local input
  local buffer = vim.fn.bufnr(form.file)
  if command and not form.project and buffer >= 0 and vim.api.nvim_buf_is_loaded(buffer) then
    if not vim.bo[buffer].modified then
      vim.api.nvim_buf_call(buffer, function()
        vim.cmd("checktime")
      end)
    end
    input = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n") .. "\n"
    command[#command] = nil -- Read this buffer through stdin rather than its older disk contents.
  end
  local function cancel()
    cancelled = true
    if process then
      process:kill(15)
    end
  end
  if not command then
    vim.schedule(function()
      if not cancelled then
        done(rows, false)
      end
    end)
    return cancel
  end
  local function line(value)
    local entry = require("forge.features.search.matches").entry(form.root, value)
    if not entry then
      return
    end
    if input then
      entry.filename = form.file
      entry.value.filename = form.file
    end
    for _, match in ipairs(entry.value.matches) do
      if #rows == 2000 then
        truncated = true
        if process then
          process:kill(15)
        end
        return
      end
      rows[#rows + 1] = {
        filename = entry.filename,
        lnum = entry.lnum,
        col = match.start + 1,
        value = {
          filename = entry.filename,
          lnum = entry.lnum,
          text = entry.value.text,
          matches = { match },
        },
      }
    end
  end
  local ok, result = pcall(vim.system, command, {
    cwd = form.root,
    text = true,
    stdin = input,
    stdout = function(error, chunk)
      if cancelled or truncated then
        return
      end
      if error then
        return
      end
      pending = pending .. (chunk or "")
      while true do
        local ending = pending:find("\n", 1, true)
        if not ending then
          break
        end
        line(pending:sub(1, ending - 1))
        pending = pending:sub(ending + 1)
        if truncated then
          break
        end
      end
    end,
  }, function(outcome)
    vim.schedule(function()
      if cancelled then
        return
      end
      process = nil
      if pending ~= "" and not truncated then
        line(pending)
      end
      table.sort(rows, function(a, b)
        if a.filename ~= b.filename then
          return a.filename < b.filename
        end
        if a.lnum ~= b.lnum then
          return a.lnum < b.lnum
        end
        return a.col < b.col
      end)
      local error
      if outcome.code ~= 0 and outcome.code ~= 1 and not truncated then
        error = vim.trim(outcome.stderr or "Search failed")
      end
      done(rows, truncated, error)
    end)
  end)
  if ok then
    process = result
  else
    vim.schedule(function()
      if not cancelled then
        done({}, false, tostring(result))
      end
    end)
  end
  return cancel
end

return M
