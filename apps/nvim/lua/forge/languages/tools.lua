local M = {}

function M.install(name, callback)
  require("lazy").load({ plugins = { "mason.nvim" } })
  local tools = require("forge.languages.profiles")[name].tools
  if #tools == 0 then
    if callback then
      callback()
    end
    return
  end
  local registry = require("mason-registry")
  registry.refresh(function()
    vim.schedule(function()
      for _, tool in ipairs(tools) do
        local ok, package = pcall(registry.get_package, tool)
        if ok and not package:is_installed() and not package:is_installing() then
          package:install()
        elseif not ok then
          vim.notify("Mason package unavailable: " .. tool, vim.log.levels.WARN)
        end
      end
      if callback then
        callback()
      end
    end)
  end)
end

local function requirements(name)
  local profile = require("forge.languages.profiles")[name]
  local lines = { profile.label, "", "SDK/runtime prerequisites (installed separately):" }
  for _, executable in ipairs(profile.requires or {}) do
    lines[#lines + 1] = (vim.fn.executable(executable) == 1 and "[available] " or "[missing] ")
      .. executable
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "Mason tools: "
    .. (#profile.tools > 0 and table.concat(profile.tools, ", ") or "uses SDK tools directly")
  lines[#lines + 1] = "Use Add SDK bin path if a runtime is outside PATH."
  lines[#lines + 1] = "Guide: docs/languages.md or the site's Languages and debug section."
  require("forge.features.picker").buffer("ForgeLanguage-" .. name, table.concat(lines, "\n"))
end

function M.choose()
  local profiles, selection =
    require("forge.languages.profiles"), require("forge.languages.selection")
  local names = vim.tbl_keys(profiles)
  table.sort(names)
  local picker = require("forge.features.picker")
  picker.select(names, {
    prompt = "Language profiles (opt-in)",
    format_item = function(name)
      return (selection.enabled(name) and "[on] " or "[off] ") .. profiles[name].label
    end,
  }, function(name)
    picker.select({
      "Enable and install tools",
      "Enable with existing tools",
      "Disable profile",
      "Show requirements",
      "Add SDK bin path",
    }, {
      prompt = profiles[name].label,
    }, function(action)
      if action == "Show requirements" then
        return requirements(name)
      end
      if action == "Add SDK bin path" then
        return require("forge.core.environment").add()
      end
      selection.set(name, action ~= "Disable profile")
      if action == "Enable and install tools" then
        M.install(name, function()
          vim.cmd("Mason")
        end)
      end
      vim.notify(
        "Language choice saved. Restart Forge after tools finish. Disabling preserves downloaded tools."
      )
    end)
  end)
end

return M
