local M = {}

function M.command(name)
  if not require("forge.languages.selection").enabled("dart") then
    return vim.notify("Enable Flutter / Dart in :ForgeLanguages first", vim.log.levels.WARN)
  end
  if vim.fn.executable("flutter") == 0 then
    return vim.notify(
      "Install the Flutter SDK or add its bin path in :ForgeLanguages",
      vim.log.levels.WARN
    )
  end
  if vim.bo.filetype ~= "dart" and vim.fn.expand("%:t") ~= "pubspec.yaml" then
    return vim.notify(
      "Open a Dart file or pubspec.yaml before using Flutter commands",
      vim.log.levels.INFO
    )
  end
  vim.cmd(name)
end

return M
