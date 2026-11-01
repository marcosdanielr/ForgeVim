local M = {}

local applied = {}

function M.apply(action, keys)
  for _, key in ipairs(applied[action.command] or {}) do
    local mapping = vim.fn.maparg(key, "n", false, true)
    if mapping.desc == action.label then
      pcall(vim.keymap.del, "n", key)
    end
  end
  applied[action.command] = keys
  for _, key in ipairs(keys) do
    vim.keymap.set("n", key, function()
      require("forge.core.commands").execute(action)
    end, { desc = action.label })
  end
end

function M.setup()
  for _, action in ipairs(require("forge.core.actions")) do
    M.apply(action, require("forge.features.shortcuts").keys(action))
  end
  vim.keymap.set("n", "<leader><space>", "<cmd>Forge<cr>", { desc = "Command palette" })
  vim.keymap.set("n", "<C-S-p>", "<cmd>Forge<cr>", { desc = "Command palette" })
  vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<Esc><cmd>update<cr>", { desc = "Save file" })
  vim.keymap.set("n", "<M-Up>", "<cmd>move -2<cr>==", { desc = "Move line up" })
  vim.keymap.set("n", "<M-Down>", "<cmd>move +1<cr>==", { desc = "Move line down" })
  vim.keymap.set("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment" })
  vim.keymap.set("x", "<C-_>", "gc", { remap = true, desc = "Toggle comment" })
  vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Leave terminal mode" })
end

return M
