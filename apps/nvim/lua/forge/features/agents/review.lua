local M = {}

function M.open(task)
  local client = require("forge.features.agents.client")
  client.request({ "review", task.id }, function(review)
    local buffer = require("forge.features.picker").buffer(
      "ForgeReview-" .. task.id,
      review.patch ~= "" and review.patch or "No changes",
      "diff"
    )
    vim.b[buffer].forge_review = { id = task.id, hash = review.hash, root = task.root }
    local function accept()
      -- Unsaved buffers are invisible to Git; keep them out of patch application.
      for _, candidate in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[candidate].modified then
          return vim.notify(
            "Save or discard modified buffers before accepting",
            vim.log.levels.WARN
          )
        end
      end
      vim.ui.select(
        { "Keep reviewing", "Accept reviewed patch" },
        { prompt = "Apply " .. task.id .. "?" },
        function(choice)
          if choice == "Accept reviewed patch" then
            client.request({ "accept", task.id, "--hash", review.hash }, function()
              vim.cmd("checktime")
              vim.notify("Reviewed patch applied. Changes remain uncommitted.")
              if vim.api.nvim_buf_is_valid(buffer) then
                vim.api.nvim_buf_delete(buffer, { force = true })
              end
            end, task.root)
          end
        end
      )
    end
    vim.keymap.set("n", "a", accept, { buffer = buffer, desc = "Accept reviewed patch" })
    vim.keymap.set("n", "r", function()
      client.request({ "reject", task.id }, function()
        vim.notify("Task rejected; worktree and logs preserved")
        if vim.api.nvim_buf_is_valid(buffer) then
          vim.api.nvim_buf_delete(buffer, { force = true })
        end
      end, task.root)
    end, { buffer = buffer, desc = "Reject task" })
    vim.notify("Review: a accepts with confirmation; r rejects; q closes")
  end, task.root)
end

return M
