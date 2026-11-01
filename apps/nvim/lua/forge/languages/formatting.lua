local M = {}

function M.options()
  local web = { "prettierd", "prettier", stop_after_first = true }
  return {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      go = { "goimports", "gofmt" },
      svelte = web,
      astro = web,
      vue = web,
      javascript = web,
      typescript = web,
      javascriptreact = web,
      typescriptreact = web,
      json = web,
      graphql = web,
      markdown = web,
      html = web,
      css = web,
      scss = web,
      java = { "google-java-format" },
      kotlin = { "ktlint" },
      ruby = { "rubocop" },
      eruby = { "htmlbeautifier" },
      sh = { "beautysh" },
      proto = { "buf" },
      rust = { "rustfmt" },
      yaml = { "yamlfix" },
      toml = { "taplo" },
      php = { "pint", "php_cs_fixer", stop_after_first = true },
      dart = { "dart_format" },
      c = { "clang_format" },
      cpp = { "clang_format" },
    },
    format_on_save = function(bufnr)
      if
        require("forge.core.config").options.format_on_save
        and require("forge.languages.selection").filetype_enabled(vim.bo[bufnr].filetype)
      then
        return { timeout_ms = 1000, lsp_format = "fallback" }
      end
    end,
    formatters = { prettier = { prepend_args = { "--prose-wrap", "always" } } },
  }
end

function M.format()
  require("conform").format({ async = true, lsp_format = "fallback" })
end

return M
