local M = {}

function M.new_file()
  local root = require("forge.core.project").root()
  vim.ui.input(
    { prompt = "New file path: ", default = root .. "/", completion = "file" },
    function(name)
      if not name or name == "" or vim.fn.isdirectory(name) == 1 then
        return
      end
      require("forge.features.panels.windows").focus_editor()
      vim.cmd.edit(vim.fn.fnameescape(name))
      vim.notify("Press i to edit. Esc returns to normal; Ctrl S saves.")
    end
  )
end

function M.cycle(direction)
  if vim.bo.buftype == "terminal" and (vim.b.forge_terminal_slot or ""):find("^terminal") then
    return require("forge.features.terminal").cycle(direction)
  end
  require("forge.features.panels.windows").focus_editor()
  vim.cmd(direction > 0 and "bnext" or "bprevious")
end

function M.cycle_next()
  M.cycle(1)
end
function M.cycle_previous()
  M.cycle(-1)
end

function M.choose()
  require("forge.features.panels.windows").focus_editor()
  require("telescope.builtin").buffers({ sort_mru = true, ignore_current_buffer = true })
end

return M
