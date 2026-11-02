local M = {}

function M.status()
  require("neogit").open({ cwd = require("forge.core.project").root() })
end

function M.commit()
  require("neogit").open({ "commit", cwd = require("forge.core.project").root() })
end

function M.history()
  local root = require("forge.core.project").root()
  vim.system(
    { "git", "-C", root, "log", "--graph", "--oneline", "--decorate", "--all", "-200" },
    { text = true },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          return vim.notify(result.stderr, vim.log.levels.WARN)
        end
        local buffer =
          require("forge.features.picker").buffer("Forge commit graph", result.stdout, "git")
        vim.keymap.set("n", "<CR>", function()
          local hash = vim.api.nvim_get_current_line():match("%f[%x](%x%x%x%x%x%x%x+)%f[^%x]")
          if hash then
            vim.cmd("DiffviewOpen -C" .. vim.fn.fnameescape(root) .. " " .. hash .. "^!")
          end
        end, { buffer = buffer, desc = "Review commit changes" })
        vim.notify("Enter reviews the commit under the cursor; q closes the graph")
      end)
    end
  )
end

function M.diff()
  vim.cmd("DiffviewOpen -C" .. vim.fn.fnameescape(require("forge.core.project").root()))
end

function M.choose_conflict()
  local choices = {
    { label = "Current / ours", side = "ours" },
    { label = "Incoming / theirs", side = "theirs" },
    { label = "Common base", side = "base" },
  }
  require("forge.features.picker").select(choices, {
    prompt = "Choose the selected conflict side; review and save the result",
    format_item = function(choice)
      return choice.label
    end,
  }, function(choice)
    require("diffview.actions").conflict_choose(choice.side)()
  end)
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
  local tree = require("nvim-tree.api").tree
  if tree.is_visible() then
    return tree.close()
  end
  tree.open({ path = require("forge.core.project").root() })
  require("forge.features.workbench.activity").reanchor(tree.winid())
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
