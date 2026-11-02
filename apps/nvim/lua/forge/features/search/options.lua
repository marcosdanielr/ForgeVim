local M = {}

function M.flags(options)
  local flags = { "--hidden", "--glob", "!.forge", "--glob", "!.git" }
  flags[#flags + 1] = options.match_case and "--case-sensitive" or "--ignore-case"
  if options.whole_word then
    flags[#flags + 1] = "--word-regexp"
  end
  if not options.regex then
    flags[#flags + 1] = "--fixed-strings"
  end
  return flags
end

return M
