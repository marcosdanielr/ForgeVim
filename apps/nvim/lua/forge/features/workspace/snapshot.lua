local M = {}

-- Read-only Git inspection. Opening the workspace never starts an AI process.
function M.load(root, callback)
  vim.system(
    { "git", "-C", root, "status", "--porcelain=v1", "--branch" },
    { text = true },
    function(result)
      local lines = vim.split(result.stdout or "", "\n", { trimempty = true })
      local snapshot = { branch = "Not a Git repository", changed = 0, conflicts = 0 }
      if result.code == 0 then
        snapshot.branch = (lines[1] or "## No commits yet"):gsub("^## ", "")
        for index = 2, #lines do
          snapshot.changed = snapshot.changed + 1
          local status = lines[index]:sub(1, 2)
          if status:find("U", 1, true) or status == "AA" or status == "DD" then
            snapshot.conflicts = snapshot.conflicts + 1
          end
        end
      end
      vim.schedule(function()
        callback(snapshot)
      end)
    end
  )
end

return M
