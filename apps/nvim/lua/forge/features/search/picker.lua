local M = {}
local active = {}

function M.apply(all)
  local controller = active[vim.api.nvim_get_current_tabpage()]
  if
    not controller
    or not controller.picker.prompt_bufnr
    or not vim.api.nvim_buf_is_valid(controller.picker.prompt_bufnr)
  then
    return false
  end
  controller.apply(all)
  return true
end

local function title(form)
  return (form.project and "Project" or "File")
    .. " · "
    .. (form.match_case and "Aa ON" or "Aa off")
    .. " · "
    .. (form.whole_word and "Word ON" or "Word off")
    .. " · "
    .. (form.regex and "Regex ON" or "Literal")
end

function M.open(form)
  local actions = require("telescope.actions")
  local state = require("telescope.actions.state")
  local picker
  local function refresh()
    form.ready = false
    picker:refresh(require("forge.features.search.finder").create(form), { reset_prompt = false })
    if picker.prompt_border then
      picker.prompt_border:change_title(title(form))
    end
  end
  local function apply(all)
    require("forge.features.search.actions").apply(form, all, refresh)
  end
  picker = require("telescope.pickers").new({
    layout_strategy = "horizontal",
    layout_config = { width = 0.92, height = 0.80, prompt_position = "top", preview_width = 0.48 },
    sorting_strategy = "ascending",
  }, {
    prompt_title = title(form),
    results_title = "Type to search · F2 replacement · Ctrl R one · Ctrl A all",
    default_text = form.search,
    finder = require("forge.features.search.finder").create(form),
    sorter = require("telescope.sorters").empty(),
    previewer = require("telescope.previewers").new_buffer_previewer({
      title = "Replacement preview",
      define_preview = function(self, entry)
        local after =
          require("forge.features.search.matches").preview(entry.value, form.replacement, false)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
          "Replace with: "
            .. (form.replacement == "" and "[empty: delete match]" or form.replacement),
          "F2 edit replacement · F3 case · F4 word",
          "F5 regex · F6 scope",
          "Ctrl R replace ONE · Ctrl A replace ALL",
          "Replacement is literal text (no $1 expansion)",
          "",
          vim.fn.fnamemodify(entry.filename, ":.") .. ":" .. entry.lnum,
          "",
          "- " .. entry.value.text,
          "+ " .. after,
        })
        vim.bo[self.state.bufnr].filetype = "diff"
      end,
    }),
    attach_mappings = function(prompt, map)
      local function edit()
        vim.cmd("stopinsert")
        require("forge.features.search.input").ask(
          "Replace with (empty deletes)",
          form.replacement,
          function(value)
            form.replacement = value
            picker:refresh_previewer()
            vim.cmd("startinsert")
          end
        )
      end
      for _, mode in ipairs({ "i", "n" }) do
        map(mode, "<F2>", edit)
        map(mode, "<C-r>", function()
          apply(false)
        end)
        map(mode, "<C-a>", function()
          apply(true)
        end)
        for key, field in pairs({
          ["<F3>"] = "match_case",
          ["<F4>"] = "whole_word",
          ["<F5>"] = "regex",
          ["<F6>"] = "project",
        }) do
          map(mode, key, function()
            if field == "project" and form.project and vim.fn.filereadable(form.file) == 0 then
              return vim.notify("Open a saved file before selecting File scope")
            end
            form[field] = not form[field]
            refresh()
          end)
        end
      end
      actions.select_default:replace(function()
        local entry = state.get_selected_entry()
        if entry then
          actions.close(prompt)
          vim.cmd.edit(vim.fn.fnameescape(entry.filename))
          vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col - 1 })
        end
      end)
      return true
    end,
  })
  picker:register_completion_callback(function()
    local count = 0
    for _, entry in ipairs(form.rows) do
      count = count + #entry.value.matches
    end
    local summary = form.error and "Invalid search: " .. form.error
      or (count .. " matches · F2 replacement · Ctrl R one · Ctrl A all")
    if form.truncated then
      summary = "2000+ matching lines · refine search for Replace all"
    end
    if picker.results_border then
      picker.results_border:change_title(summary)
    end
  end)
  active[vim.api.nvim_get_current_tabpage()] = { picker = picker, apply = apply }
  picker:find()
  return picker
end

return M
