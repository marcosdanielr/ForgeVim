-- Package names are Mason registry names. Runtime toolchains remain user-managed.
return {
  lua = { label = "Lua", server = "lua_ls", tools = { "lua-language-server", "stylua" } },
  python = {
    label = "Python",
    server = "pyright",
    tools = { "pyright", "black", "isort", "debugpy" },
  },
  go = { label = "Go", server = "gopls", tools = { "gopls", "goimports", "delve" } },
  rust = {
    label = "Rust / C / C++",
    server = "rust_analyzer",
    tools = { "rust-analyzer", "codelldb", "clang-format" },
  },
  typescript = {
    label = "JavaScript / TypeScript",
    server = "ts_ls",
    tools = { "typescript-language-server", "prettierd", "js-debug-adapter" },
  },
  php = {
    label = "PHP",
    server = "phpactor",
    tools = { "phpactor", "pint", "php-cs-fixer", "php-debug-adapter" },
  },
  web = { label = "HTML / Astro", tools = { "html-lsp", "astro-language-server", "prettierd" } },
  dart = { label = "Dart / Flutter (install Flutter SDK separately)", tools = {} },
  java = { label = "Java formatting", tools = { "google-java-format" } },
  kotlin = { label = "Kotlin formatting", tools = { "ktlint" } },
  ruby = { label = "Ruby / ERB formatting", tools = { "rubocop", "htmlbeautifier" } },
  shell = { label = "Shell formatting", tools = { "beautysh" } },
  data = { label = "YAML / TOML / Protobuf formatting", tools = { "yamlfix", "taplo", "buf" } },
}
