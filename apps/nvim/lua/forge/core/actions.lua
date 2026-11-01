-- The palette, Ex commands, and leader mappings share the same actions.
local function feature(module, method, ...)
  local arguments = { ... }
  return function()
    require("forge." .. module)[method](unpack(arguments))
  end
end
local function debug(method)
  return function()
    require("dap")[method]()
  end
end

return {
  {
    command = "ForgeLazygit",
    label = "Open lazygit terminal",
    keys = { "<leader>gL" },
    run = feature("features.git", "lazygit"),
  },
  {
    command = "ForgeDefinition",
    label = "Go to symbol definition",
    keys = { "gd", "<F12>", "<leader>cd" },
    run = vim.lsp.buf.definition,
  },
  {
    command = "ForgeReferences",
    label = "Find symbol references",
    keys = { "grr", "<S-F12>", "<leader>cR" },
    run = vim.lsp.buf.references,
  },
  {
    command = "ForgeHover",
    label = "Show symbol documentation",
    keys = { "K", "<leader>ch" },
    run = vim.lsp.buf.hover,
  },
  {
    command = "ForgeSignature",
    label = "Show function signature",
    keys = { "<leader>cs" },
    run = vim.lsp.buf.signature_help,
  },
  {
    command = "ForgeImplementation",
    label = "Go to implementation",
    keys = { "gi", "<leader>ci" },
    run = vim.lsp.buf.implementation,
  },
  {
    command = "ForgeTypeDefinition",
    label = "Go to type definition",
    keys = { "gy", "<leader>cy" },
    run = vim.lsp.buf.type_definition,
  },
  {
    command = "ForgeDiagnostics",
    label = "Show line diagnostics",
    keys = { "gl", "<leader>ce" },
    run = function()
      vim.diagnostic.open_float(nil, { scope = "line", border = "single" })
    end,
  },
  {
    command = "ForgeDiagnosticNext",
    label = "Next diagnostic",
    keys = { "]d", "<leader>cn" },
    run = function()
      vim.diagnostic.jump({ count = 1, float = true })
    end,
  },
  {
    command = "ForgeDiagnosticPrevious",
    label = "Previous diagnostic",
    keys = { "[d", "<leader>cp" },
    run = function()
      vim.diagnostic.jump({ count = -1, float = true })
    end,
  },
  {
    command = "ForgeSymbols",
    label = "Search document symbols",
    keys = { "<leader>fs" },
    run = function()
      require("telescope.builtin").lsp_document_symbols()
    end,
  },
  {
    command = "ForgeTree",
    label = "Toggle file tree",
    keys = { "<C-b>", "<leader>fe" },
    run = feature("features.git", "tree"),
  },
  {
    command = "ForgeGit",
    label = "Git status, stage and commit",
    keys = { "<C-S-g>", "<leader>gg" },
    run = feature("features.git", "status"),
  },
  {
    command = "ForgeDiff",
    label = "Review working tree diff",
    keys = { "<leader>gd" },
    run = feature("features.git", "diff"),
  },
  {
    command = "ForgeConflicts",
    label = "Resolve Git conflicts",
    keys = { "<leader>gm" },
    run = feature("features.git", "conflicts"),
  },
  {
    command = "ForgeKeymaps",
    label = "Configure shortcuts",
    keys = { "<leader>uk" },
    run = feature("features.shortcuts", "choose"),
  },
  {
    command = "ForgeAgentConnect",
    label = "Connect agent account",
    keys = { "<leader>ac" },
    run = feature("features.agents.providers", "connect"),
  },
  {
    command = "ForgeNotifications",
    label = "Toggle agent notifications",
    keys = { "<leader>un" },
    run = feature("features.agents.notifications", "toggle"),
  },
  {
    command = "ForgeFiles",
    label = "Find files",
    keys = { "<C-p>", "<leader>ff" },
    run = feature("features.search", "files"),
  },
  {
    command = "ForgeSearch",
    label = "Search project text",
    keys = { "<C-S-f>", "<leader>fg" },
    run = feature("features.search", "project"),
  },
  {
    command = "ForgeBufferSearch",
    label = "Search current buffer",
    keys = { "<C-f>", "<leader>fb" },
    run = feature("features.search", "buffer"),
  },
  {
    command = "ForgeReplace",
    label = "Replace in project",
    keys = { "<C-S-h>", "<leader>fr" },
    run = feature("features.search", "replace", true),
  },
  {
    command = "ForgeBufferReplace",
    label = "Replace in current file",
    keys = { "<leader>fR" },
    run = feature("features.search", "replace", false),
  },
  {
    command = "ForgeThemes",
    label = "Choose theme",
    keys = { "<leader>ut" },
    run = feature("features.themes", "choose"),
  },
  {
    command = "ForgePlugins",
    label = "Manage plugins",
    keys = { "<leader>up" },
    run = feature("features.plugins", "choose"),
  },
  {
    command = "ForgeLanguages",
    label = "Install language tools",
    keys = { "<leader>ul" },
    run = feature("languages.tools", "choose"),
  },
  {
    command = "ForgeFormat",
    label = "Format code",
    keys = { "<M-S-f>", "<leader>cf" },
    run = feature("languages.formatting", "format"),
  },
  {
    command = "ForgeRename",
    label = "Rename symbol with LSP",
    keys = { "<F2>", "<leader>cr" },
    run = vim.lsp.buf.rename,
  },
  {
    command = "ForgeCodeAction",
    label = "LSP code action",
    keys = { "<leader>ca" },
    run = vim.lsp.buf.code_action,
  },
  {
    command = "ForgeAgentStart",
    label = "Start agent task",
    keys = { "<leader>an" },
    run = feature("features.agents", "start"),
  },
  {
    command = "ForgeAgents",
    label = "List and review agents",
    keys = { "<leader>aa" },
    run = feature("features.agents", "choose"),
  },
  {
    command = "ForgeDebug",
    label = "Start / continue debug",
    keys = { "<F5>", "<leader>dc" },
    run = debug("continue"),
  },
  {
    command = "ForgeBreakpoint",
    label = "Toggle breakpoint",
    keys = { "<F9>", "<leader>db" },
    run = debug("toggle_breakpoint"),
  },
  {
    command = "ForgeStepOver",
    label = "Debug step over",
    keys = { "<F10>", "<leader>do" },
    run = debug("step_over"),
  },
  {
    command = "ForgeStepInto",
    label = "Debug step into",
    keys = { "<F11>", "<leader>di" },
    run = debug("step_into"),
  },
  {
    command = "ForgeStepOut",
    label = "Debug step out",
    keys = { "<S-F11>", "<leader>dO" },
    run = debug("step_out"),
  },
  {
    command = "ForgeDebugStop",
    label = "Stop debug",
    keys = { "<S-F5>", "<leader>dq" },
    run = debug("terminate"),
  },
  {
    command = "ForgeDebugUI",
    label = "Toggle debug panels",
    keys = { "<leader>du" },
    run = function()
      require("dapui").toggle()
    end,
  },
  {
    command = "ForgeDebugLoadLaunch",
    label = "Load trusted .vscode/launch.json",
    keys = { "<leader>dl" },
    run = feature("languages.debug", "launch_json"),
  },
  {
    command = "ForgeHealth",
    label = "Check Forge requirements",
    keys = { "<leader>uh" },
    run = function()
      vim.cmd("checkhealth forge")
    end,
  },
}
