local M = {}

function M.status()
  require("neogit").open({ cwd = require("forge.core.project").root() })
end

function M.diff()
  vim.cmd("DiffviewOpen -C" .. vim.fn.fnameescape(require("forge.core.project").root()))
end

function M.conflicts()
  local root = require("forge.core.project").root()
  vim.system(
    { "git", "-C", root, "diff", "--name-only", "--diff-filter=U" },
    { text = true },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          return vim.notify(result.stderr, vim.log.levels.ERROR)
        end
        if not result.stdout:match("%S") then
          return vim.notify("No unresolved merge conflicts")
        end
        vim.cmd("DiffviewOpen -C" .. vim.fn.fnameescape(root))
        vim.notify("Conflicts: ]x / [x navigate; Space co ours, ct theirs, cb base; :write saves")
      end)
    end
  )
end

function M.tree()
  require("nvim-tree.api").tree.toggle({ path = require("forge.core.project").root() })
end

function M.lazygit()
  if vim.fn.executable("lazygit") == 0 then
    return vim.notify("Install lazygit CLI to use this optional workflow", vim.log.levels.WARN)
  end
  local root = require("forge.core.project").root()
  vim.cmd("tabnew")
  vim.fn.jobstart({ "lazygit" }, { term = true, cwd = root })
  vim.cmd("startinsert")
end

return M
