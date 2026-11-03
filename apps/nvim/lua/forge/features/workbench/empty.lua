local M = {}
local content = {
  chat = {
    title = "Chat",
    filetype = "forge-chat-welcome",
    lines = {
      "",
      "  YOUR AGENTS, YOUR WORKFLOW",
      "",
      "  Start an isolated conversation.",
      "  Review changes before applying.",
      "",
      "  Codex · Claude Code · Gemini",
      "",
      "  [n] New conversation",
      "  [c] Connect an account",
      "",
      "  Uses your provider's official CLI.",
      "  No agent starts automatically.",
      "",
      "  Leader pc  Hide or show chat",
    },
    actions = { n = "ForgeChatNew", c = "ForgeAgentConnect" },
  },
  terminal = {
    title = "Output · Terminal",
    filetype = "forge-terminal-welcome",
    lines = {
      "",
      "  Ready when you are.",
      "",
      "  [Enter] Open terminal",
      "  Leader ot  Toggle terminal",
      "  Leader oT New terminal",
      "  Leader os Split terminal",
      "",
      "  Hidden terminals keep running.",
    },
    actions = { ["<CR>"] = "ForgeTerminalNew", n = "ForgeTerminalNew" },
  },
  logs = {
    title = "Agent logs",
    filetype = "forge-logs-welcome",
    lines = {
      "",
      "  No agent selected.",
      "",
      "  Select an agent and press L",
      "  to inspect its logs.",
      "",
      "  [a] Open agents",
      "  Leader pl  Toggle logs",
    },
    actions = { a = "ForgeAgents" },
  },
}

function M.open(id, options)
  local windows = require("forge.features.panels.windows")
  if windows.get(id) then
    return
  end
  local specification = assert(content[id])
  local text = require("forge.features.panels.text")
  local buffer =
    text.create(specification.title, require("forge.core.project").root(), specification.filetype)
  vim.bo[buffer].bufhidden = "wipe"
  text.write(buffer, specification.lines)
  local namespace = vim.api.nvim_create_namespace("forge-empty")
  for row, line in ipairs(specification.lines) do
    vim.api.nvim_buf_set_extmark(buffer, namespace, row - 1, 0, {
      end_col = #line,
      hl_group = line:find("%[") and "ForgeAccent" or "ForgeMuted",
    })
  end
  local rows = {}
  for row, line in ipairs(specification.lines) do
    for key, command in pairs(specification.actions) do
      if line:find("[" .. (key == "<CR>" and "Enter" or key) .. "]", 1, true) then
        rows[row] = command
      end
    end
  end
  local function activate()
    local command = rows[vim.api.nvim_win_get_cursor(0)[1]]
    if command then
      vim.cmd(command)
    end
  end
  vim.keymap.set(
    "n",
    "<2-LeftMouse>",
    activate,
    { buffer = buffer, desc = "Activate panel action" }
  )
  if not specification.actions["<CR>"] then
    vim.keymap.set("n", "<CR>", activate, { buffer = buffer, desc = "Activate panel action" })
  end
  for key, command in pairs(specification.actions) do
    vim.keymap.set("n", key, "<cmd>" .. command .. "<cr>", { buffer = buffer, desc = command })
  end
  vim.keymap.set("n", "q", function()
    windows.hide(id)
  end, { buffer = buffer, desc = "Hide panel" })
  return windows.show(
    id,
    buffer,
    vim.tbl_extend("force", { title = specification.title, focus = false }, options or {})
  )
end

return M
