-- One status read per project fans out to panels and optional notifications.
local M = {}
local roots = {}
local active = { queued = true, running = true, cancelling = true }

local function stop(state)
  for _, handle in ipairs({ state.timer, state.event }) do
    if handle and not handle:is_closing() then
      handle:stop()
      handle:close()
    end
  end
end

local function install_event(state)
  if state.event or not vim.uv.fs_stat(state.root .. "/.forge/events.signal") then
    return
  end
  local event = assert(vim.uv.new_fs_event())
  local ok = event:start(
    state.root .. "/.forge/events.signal",
    {},
    vim.schedule_wrap(function()
      if state.scheduled then
        return
      end
      state.scheduled = true
      vim.defer_fn(function()
        state.scheduled = false
        if roots[state.root] == state then
          M.refresh(state.root)
        end
      end, 75)
    end)
  )
  if ok then
    state.event = event
  else
    event:close()
  end
end

function M.refresh(root)
  local state = roots[root]
  if not state then
    return
  end
  if state.busy then
    state.dirty = true
    return
  end
  state.busy = true
  require("forge.features.agents.client").request(
    { "list" },
    function(tasks)
      state.busy = false
      if roots[root] ~= state then
        return
      end
      install_event(state)
      local running = false
      for _, task in ipairs(tasks) do
        if active[task.status] then
          running = true
        end
      end
      if running then
        state.timer:start(
          5000,
          5000,
          vim.schedule_wrap(function()
            M.refresh(root)
          end)
        )
      else
        state.timer:stop()
      end
      for _, listener in pairs(state.listeners) do
        listener.data(tasks)
      end
      if state.dirty then
        state.dirty = false
        vim.defer_fn(function()
          if roots[root] == state then
            M.refresh(root)
          end
        end, 75)
      end
    end,
    root,
    function(error)
      state.busy = false
      if roots[root] ~= state then
        return
      end
      for _, listener in pairs(state.listeners) do
        if listener.error then
          listener.error(error)
        end
      end
    end
  )
end

function M.subscribe(root, id, on_data, on_error)
  local state = roots[root]
  if not state then
    state = { root = root, listeners = {}, timer = assert(vim.uv.new_timer()) }
    roots[root] = state
  end
  local added = state.listeners[id] == nil
  state.listeners[id] = { data = on_data, error = on_error }
  install_event(state)
  if added then
    M.refresh(root)
  end
  return added
end

function M.unsubscribe(root, id)
  local state = roots[root]
  if not state then
    return
  end
  state.listeners[id] = nil
  if next(state.listeners) == nil then
    roots[root] = nil
    stop(state)
  end
end

return M
