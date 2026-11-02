return function()
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, "p")
  local first, second = root .. "/one space.txt", root .. "/two.txt"
  vim.fn.writefile({ "á needle needle" }, first)
  vim.fn.writefile({ "NEEDLE" }, second)
  local form = { root = root, file = first, project = true, regex = false, match_case = false }
  local function records()
    local output = vim
      .system(
        require("forge.features.search.matches").command(form, "needle"),
        { cwd = root, text = true }
      )
      :wait()
    assert(output.code == 0, output.stderr)
    local results = {}
    for line in output.stdout:gmatch("[^\n]+") do
      local entry = require("forge.features.search.matches").entry(root, line)
      if entry then
        results[#results + 1] = entry.value
      end
    end
    return results
  end
  local matches = records()
  local selected
  for _, record in ipairs(matches) do
    if record.filename == first then
      selected = record
    end
  end
  assert(selected and #selected.matches == 2, "ripgrep lost multiple matches on one line")
  local replace = require("forge.features.search.replacement").apply
  assert(replace({ selected }, "done", false) == 1)
  assert(
    vim.fn.readfile(first)[1] == "á done needle",
    "Replace one changed more than one occurrence or broke UTF-8"
  )
  assert(replace(records(), "done", true) == 2)
  assert(
    vim.fn.readfile(first)[1] == "á done done" and vim.fn.readfile(second)[1] == "done",
    "Replace all missed matches"
  )
  vim.fn.writefile({ "á needle needle" }, first)
  vim.fn.writefile({ "NEEDLE" }, second)
  local occurrences = {}
  for _, record in ipairs(records()) do
    for _, match in ipairs(record.matches) do
      occurrences[#occurrences + 1] = {
        filename = record.filename,
        lnum = record.lnum,
        text = record.text,
        matches = { match },
      }
    end
  end
  assert(replace(occurrences, "different length", true) == 3)
  assert(
    vim.fn.readfile(first)[1] == "á different length different length",
    "Per-occurrence Replace all used shifted byte offsets"
  )
  vim.fn.writefile({ "needle original" }, first)
  local stale = records()
  vim.fn.writefile({ "changed externally and preserved" }, first)
  assert(not pcall(replace, stale, "lost", true), "Stale results were applied")
  assert(vim.fn.readfile(first)[1] == "changed externally and preserved")
  vim.fn.writefile({ "needle" }, second)
  local dirty = records()
  local buffer = vim.fn.bufadd(second)
  vim.fn.bufload(buffer)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "unsaved editor work" })
  assert(not pcall(replace, dirty, "lost", true), "Replacement overwrote unsaved work")
  assert(vim.fn.readfile(second)[1] == "needle")
  for _, filename in ipairs({ first, second }) do
    local candidate = vim.fn.bufnr(filename)
    if candidate >= 0 then
      vim.api.nvim_buf_delete(candidate, { force = true })
    end
  end
  vim.fn.delete(root, "rf")
end
