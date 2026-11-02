local M = {}

local applied = {}

-- Printable prefixes belong to the shell/chat, including a user-selected Leader.
local function terminal_safe(key)
  local expanded = key
    :gsub("<[Ll][Ee][Aa][Dd][Ee][Rr]>", function()
      return vim.g.mapleader or "\\"
    end)
    :gsub("<[Ll][Oo][Cc][Aa][Ll][Ll][Ee][Aa][Dd][Ee][Rr]>", function()
      return vim.g.maplocalleader or "\\"
    end)
  local first = vim.api.nvim_replace_termcodes(expanded, true, true, true):byte()
  return first and (first < 32 or first == 127 or first == 128)
end

function M.apply(action, keys)
  local modes = action.terminal and { "n", "t" } or { "n" }
  for _, mode in ipairs(modes) do
    for _, key in ipairs(applied[action.command] or {}) do
      local mapping = vim.fn.maparg(key, mode, false, true)
      if mapping.desc == action.label then
        pcall(vim.keymap.del, mode, key)
      end
    end
    for _, key in ipairs(keys) do
      if
        mode == "t"
        and terminal_safe(key)
        and not vim.tbl_contains(action.terminal_exclude or {}, key)
      then
        vim.keymap.set(
          mode,
          key,
          "<C-\\><C-n><cmd>" .. action.command .. "<cr>",
          { desc = action.label }
        )
      elseif mode == "n" then
        vim.keymap.set(mode, key, function()
          require("forge.core.commands").execute(action)
        end, { desc = action.label })
      end
    end
  end
  applied[action.command] = keys
end

function M.setup()
  for _, action in ipairs(require("forge.core.actions")) do
    M.apply(action, require("forge.features.shortcuts").keys(action))
  end
  vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<Esc><cmd>update<cr>", { desc = "Save file" })
  vim.keymap.set("n", "<M-Up>", "<cmd>move -2<cr>==", { desc = "Move line up" })
  vim.keymap.set("n", "<M-Down>", "<cmd>move +1<cr>==", { desc = "Move line down" })
  vim.keymap.set("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment" })
  vim.keymap.set("x", "<C-_>", "gc", { remap = true, desc = "Toggle comment" })
  vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Leave terminal mode" })
end

return M
