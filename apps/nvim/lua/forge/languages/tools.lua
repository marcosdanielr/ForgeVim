local M = {}

function M.choose()
  require("lazy").load({ plugins = { "mason.nvim" } })
  local profiles = require("forge.languages.profiles")
  local names = vim.tbl_keys(profiles)
  table.sort(names)
  require("forge.features.picker").select(names, {
    prompt = "Install language tools (explicit opt-in)",
    format_item = function(name)
      return profiles[name].label
    end,
  }, function(name)
    if #profiles[name].tools == 0 then
      return vim.notify("Install the Flutter SDK; dartls uses flutter analysis-server --lsp.")
    end
    local registry = require("mason-registry")
    registry.refresh(function()
      vim.schedule(function()
        for _, tool in ipairs(profiles[name].tools) do
          local ok, package = pcall(registry.get_package, tool)
          if ok and not package:is_installed() and not package:is_installing() then
            package:install()
          elseif not ok then
            vim.notify("Mason package unavailable: " .. tool, vim.log.levels.WARN)
          end
        end
        vim.cmd("Mason")
        vim.notify("Restart after installation to enable newly available language servers.")
      end)
    end)
  end)
end

return M
