local M = {}

function M.create(form)
  local process
  local generation = 0
  local finder = {}
  function finder.close()
    generation = generation + 1
    if process then
      process:kill(15)
      process = nil
    end
  end
  return setmetatable(finder, {
    __call = function(_, query, result, complete)
      finder.close()
      local current = generation
      form.search, form.rows, form.ready, form.truncated, form.error = query, {}, false, false, nil
      local command = require("forge.features.search.matches").command(form, query)
      if not command then
        form.ready = true
        complete()
        return
      end
      local pending = ""
      local function line(text)
        local entry = require("forge.features.search.matches").entry(form.root, text)
        if entry then
          if #form.rows >= 2000 then
            form.truncated = true
            if process then
              process:kill(15)
            end
            return
          end
          form.rows[#form.rows + 1] = entry
        end
      end
      process = vim.system(command, {
        cwd = form.root,
        text = true,
        stdout = function(error, chunk)
          if current ~= generation or form.truncated then
            return
          end
          if error then
            form.error = tostring(error)
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
            if form.truncated then
              break
            end
          end
        end,
      }, function(outcome)
        vim.schedule(function()
          if current ~= generation then
            return
          end
          process = nil
          if pending ~= "" and not form.truncated then
            line(pending)
          end
          if outcome.code ~= 0 and outcome.code ~= 1 and not form.truncated then
            form.error = (outcome.stderr or "Search failed"):gsub("%s+$", "")
          end
          form.ready = true
          for _, entry in ipairs(form.rows) do
            if result(entry) then
              break
            end
          end
          complete()
        end)
      end)
    end,
  })
end

return M
