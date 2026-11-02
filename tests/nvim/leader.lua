local function exercise()
  local expected = vim.env.FORGE_EXPECTED_LEADER
  assert(vim.g.mapleader == expected, "Configured Leader did not load")
  assert(
    vim.fn.maparg(expected .. "fz", "n", false, true).desc == "Find files",
    "Custom action mapping lost its Leader"
  )
  assert(
    vim.fn.maparg(expected .. expected, "n", false, true).desc == "Command palette",
    "Double Leader palette missing"
  )
  for _, previous in ipairs({ " ", ",", ";" }) do
    if previous ~= expected then
      assert(vim.fn.maparg(previous .. "fz", "n") == "", "Old Leader mapping survived restart")
    end
  end
  local leader = require("forge.features.leader")
  assert(leader.normalize("<Space>") == " ")
  assert(not leader.normalize(""))
  assert(not leader.normalize("ab"))
  assert(not leader.normalize("\n"))
  if vim.env.FORGE_NEXT_LEADER then
    leader.save(vim.env.FORGE_NEXT_LEADER)
    assert(vim.g.mapleader == expected, "Leader changed before restart")
    assert(
      vim.fn.maparg(expected .. "fz", "n", false, true).desc == "Find files",
      "Saving Leader removed live mappings"
    )
  end
  local state = require("forge.core.state").read()
  assert(state.future_marker == "preserved", "Leader preference dropped unknown state")
  assert(state.keymaps.ForgeFiles[1] == "<leader>fz", "Custom mapping was destructively expanded")
end
local ok, failure = xpcall(exercise, debug.traceback)
if ok then
  vim.cmd("qa!")
else
  io.stderr:write(failure .. "\n")
  vim.cmd("cquit 1")
end
