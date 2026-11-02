local M = {}

function M.open()
  local lines = {
    "FORGE / QUICK START",
    "",
    "Edit: i enters insert mode. Esc returns to normal. Ctrl S saves.",
    "Move: h left, j down, k up, l right. These stay native in files.",
    "Windows: Ctrl H/J/K/L or Ctrl W then h/j/k/l focuses a panel.",
    "Explorer: j/k selects; l or Enter opens; h collapses the folder.",
    "Mouse: click to focus, drag split borders, double-click panel actions.",
    "",
    "PANELS / ACTIONS (your configured shortcuts)",
    "",
  }
  local wanted = {
    ForgeTree = true,
    ForgeAgents = true,
    ForgeChat = true,
    ForgeChatNew = true,
    ForgeTerminal = true,
    ForgeTerminalNew = true,
    ForgeTerminalSplit = true,
    ForgeTerminals = true,
    ForgeBufferNext = true,
    ForgeBufferPrevious = true,
    ForgeBuffers = true,
    ForgeReplace = true,
    ForgeBufferReplace = true,
    ForgeGit = true,
    ForgeGitHistory = true,
    ForgeCommit = true,
    ForgeConflicts = true,
    ForgePanelDebug = true,
    ForgePanelReview = true,
    ForgeProblems = true,
    ForgeSettings = true,
  }
  for _, action in ipairs(require("forge.core.actions")) do
    if wanted[action.command] then
      local keys = table
        .concat(require("forge.features.shortcuts").keys(action), " / ")
        :gsub("<leader>", "Space ")
      lines[#lines + 1] = action.label .. "  " .. keys .. "  :" .. action.command
    end
  end
  vim.list_extend(lines, {
    "",
    "SEARCH & REPLACE",
    "",
    "Select File or Project, Match case, Whole word, and Regex.",
    "Preview first. In grug-far, g? shows apply/undo actions.",
    "",
    "GIT",
    "",
    "Source control: Tab expands, s stages, u unstages, c opens commit options.",
    "Conflicts: ]x/[x selects; Space cm chooses Current / Incoming / Base.",
    "Review the result and save before staging. Nothing commits automatically.",
    "",
    "CHAT",
    "",
    "Each CLI chat uses its own worktree and the provider's normal login.",
    "Exit the CLI to finish; Agents then offers Review changes.",
    "Hiding a terminal or chat keeps its process running while Forge stays open.",
    "Terminal keys require modern terminal support; Space shortcuts always work.",
    "",
    "q hides this help.",
  })
  require("forge.features.panels.text").show(
    "help",
    "Getting started / q hide",
    table.concat(lines, "\n"),
    require("forge.core.project").root()
  )
end

return M
