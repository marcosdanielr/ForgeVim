local M = {}
local letters = {
  F = { "████", "█   ", "███ ", "█   ", "█   " },
  O = { " ██ ", "█  █", "█  █", "█  █", " ██ " },
  R = { "███ ", "█  █", "███ ", "█ █ ", "█  █" },
  G = { " ███", "█   ", "█ ██", "█  █", " ███" },
  E = { "████", "█   ", "███ ", "█   ", "████" },
  V = { "█  █", "█  █", "█  █", "█  █", " ██ " },
  I = { "███", " █ ", " █ ", " █ ", "███" },
  M = { "█   █", "██ ██", "█ █ █", "█   █", "█   █" },
}

function M.lines(width)
  if width < 48 then
    return { "F O R G E V I M" }
  end
  local rows = {}
  for row = 1, 5 do
    local pieces = {}
    for letter in ("FORGEVIM"):gmatch(".") do
      pieces[#pieces + 1] = letters[letter][row]
    end
    rows[row] = table.concat(pieces, " ")
  end
  return rows
end

return M
