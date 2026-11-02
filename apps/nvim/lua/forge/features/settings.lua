local M = {}

function M.layout()
  local state = require("forge.core.state").read()
  local welcome = state.workspace
  if welcome == nil then
    welcome = require("forge.core.config").options.workspace
  end
  local choices = {
    { label = "Welcome screen", key = "workspace", enabled = welcome },
    {
      label = "Files sidebar",
      key = "files",
      enabled = require("forge.features.layout").enabled("files"),
    },
    {
      label = "Agents sidebar (wide terminals)",
      key = "agents",
      enabled = require("forge.features.layout").enabled("agents"),
    },
  }
  for _, panel in ipairs({
    { "Navigation rail", "navigation" },
    { "CLI chat", "chat" },
    { "Output dock", "output" },
  }) do
    choices[#choices + 1] = {
      label = panel[1],
      key = panel[2],
      enabled = require("forge.features.layout").enabled(panel[2]),
    }
  end
  require("forge.features.picker").select(choices, {
    prompt = "Startup layout (saved for next launch)",
    format_item = function(item)
      return (item.enabled and "[x] " or "[ ] ") .. item.label
    end,
  }, function(item)
    if item.key == "workspace" then
      state.workspace = not item.enabled
    else
      state.startup_panels = state.startup_panels or {}
      state.startup_panels[item.key] = not item.enabled
    end
    require("forge.core.state").write(state)
    M.layout()
  end)
end

function M.open()
  local choices = {
    { label = "Startup layout", command = "ForgeStartupLayout" },
    { label = "Theme", command = "ForgeThemes" },
    { label = "Keyboard shortcuts", command = "ForgeKeymaps" },
    { label = "Languages and formatters", command = "ForgeLanguages" },
    { label = "Plugins and Copilot", command = "ForgePlugins" },
    { label = "Connect an AI account", command = "ForgeAgentConnect" },
    { label = "Toggle agent notifications", command = "ForgeNotifications" },
    { label = "Check installed tools", command = "ForgeHealth" },
    { label = "Getting started and panel keys", command = "ForgeHelp" },
  }
  require("forge.features.picker").select(choices, {
    prompt = "Forge settings",
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    vim.cmd(item.command)
  end)
end

return M
