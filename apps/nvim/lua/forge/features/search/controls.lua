local M = {}
local order = { "search", "replacement", "results", "actions", "options" }

function M.attach(dialog)
  local windows = dialog.windows
  local function cycle(back)
    local current = vim.api.nvim_get_current_win()
    for index, name in ipairs(order) do
      if windows[name].window == current then
        dialog:focus(order[(index - 1 + (back and -1 or 1)) % #order + 1])
        return
      end
    end
    dialog:focus("search")
  end
  for name, pane in pairs(windows) do
    if type(pane) == "table" and pane.buffer then
      local function map(key, action)
        vim.keymap.set({ "n", "i" }, key, action, { buffer = pane.buffer, silent = true })
      end
      map("<LeftMouse>", function()
        local mouse = vim.fn.getmousepos()
        for target, window in pairs(windows) do
          if type(window) == "table" and window.window == mouse.winid then
            dialog:focus(target, mouse.column - 1)
            if target == "actions" or target == "options" then
              if mouse.line ~= 1 then
                return
              end
              for index, range in ipairs(window.ranges) do
                if mouse.column - 1 >= range.first and mouse.column - 1 < range.last then
                  if target == "actions" then
                    dialog:activate(index)
                  else
                    dialog:toggle(index)
                  end
                  return
                end
              end
            elseif target == "results" and dialog.form.rows[mouse.line] then
              dialog.selected = mouse.line
              dialog:render()
            end
            return
          end
        end
      end)
      map("<Tab>", function()
        cycle(false)
      end)
      map("<S-Tab>", function()
        cycle(true)
      end)
      map("<C-r>", function()
        dialog:apply(false)
      end)
      map("<C-a>", function()
        dialog:apply(true)
      end)
      map("<F2>", function()
        dialog:focus("replacement")
      end)
      for key, option in pairs({ ["<F3>"] = 1, ["<F4>"] = 2, ["<F5>"] = 3, ["<F6>"] = 4 }) do
        map(key, function()
          dialog:toggle(option)
        end)
      end
      vim.keymap.set("n", "<Esc>", function()
        if dialog.confirming then
          dialog.confirming = false
          dialog.action = 1
          dialog:render()
        else
          dialog:close()
        end
      end, { buffer = pane.buffer })
      if name == "search" or name == "replacement" then
        map("<CR>", function()
          dialog:focus("results")
        end)
        vim.keymap.set("i", "<C-u>", function()
          vim.api.nvim_buf_set_lines(pane.buffer, 0, -1, false, { "" })
        end, { buffer = pane.buffer })
      end
    end
  end
  for _, name in ipairs({ "actions", "options" }) do
    local pane = windows[name]
    local field = name == "actions" and "action" or "option"
    local function activate(index)
      if name == "actions" then
        dialog:activate(index)
      else
        dialog:toggle(index)
      end
    end
    local function move(delta)
      local total = #pane.ranges
      dialog[field] = (dialog[field] - 1 + delta) % total + 1
      dialog:render()
    end
    for key, delta in pairs({ h = -1, l = 1, ["<Left>"] = -1, ["<Right>"] = 1 }) do
      vim.keymap.set("n", key, function()
        move(delta)
      end, { buffer = pane.buffer })
    end
    vim.keymap.set("n", "<CR>", function()
      activate(dialog[field])
    end, { buffer = pane.buffer })
  end
  for key, delta in pairs({ j = 1, k = -1, ["<Down>"] = 1, ["<Up>"] = -1 }) do
    vim.keymap.set("n", key, function()
      dialog.selected = math.max(1, math.min(#dialog.form.rows, dialog.selected + delta))
      dialog:render()
    end, { buffer = windows.results.buffer })
  end
  vim.keymap.set("n", "<CR>", function()
    dialog:open_result()
  end, { buffer = windows.results.buffer })
  local group =
    vim.api.nvim_create_augroup("ForgeReplace" .. windows.frame.buffer, { clear = true })
  dialog.group = group
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    buffer = windows.results.buffer,
    callback = function()
      if dialog.closed then
        return
      end
      local row = vim.api.nvim_win_get_cursor(windows.results.window)[1]
      if row ~= dialog.selected then
        dialog.selected = row
        dialog:render()
      end
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = vim.tbl_map(function(name)
      return tostring(windows[name].window)
    end, { "frame", "search", "replacement", "options", "results", "preview", "actions" }),
    callback = function()
      dialog:close()
    end,
  })
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      dialog:resize()
    end,
  })
end

return M
