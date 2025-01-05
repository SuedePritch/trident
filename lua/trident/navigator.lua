local api = vim.api
local ui = require("trident.ui")
local terminal = require("trident.terminal")

local M = {}
local parts = {}

local function get_current_directory()
  local bufname = api.nvim_buf_get_name(0)
  if bufname == "" then
    return vim.fn.getcwd()
  end
  return vim.fn.fnamemodify(bufname, ":p:h")
end

local function build_directory_lines()
  local cwd = get_current_directory()
  parts = {}

  for folder in cwd:gmatch("[^/]+") do
    table.insert(parts, folder)
  end

  -- Prepend root slash
  table.insert(parts, 1, "/")
  return parts
end

-- Called after the user presses Enter on the directory
function M.open_terminal_with_selection()
  local cursor = api.nvim_win_get_cursor(0)
  local selected_part = table.concat(parts, "/", 1, cursor[1])
  vim.cmd("close")  -- close the floating navigator
  terminal.open_terminal_with_selection(selected_part)
end

-- Cursor movement
function M.move_up()
  local cursor = api.nvim_win_get_cursor(0)
  if cursor[1] > 1 then
    api.nvim_win_set_cursor(0, { cursor[1] - 1, 0 })
  end
end

function M.move_down()
  local cursor = api.nvim_win_get_cursor(0)
  if cursor[1] < #parts then
    api.nvim_win_set_cursor(0, { cursor[1] + 1, 0 })
  end
end

function M.create_floating_directory_navigator()
  -- Build the directory lines
  local dir_lines = build_directory_lines()

  -- Create the titled menu
  local buf, main_win, title_win, close_both = ui.create_titled_menu(
    "Select directory to open terminal",
    dir_lines,
    13 -- offset for spacing, matching your original approach
  )

  -- Highlight last directory (current)
  api.nvim_buf_add_highlight(buf, 0, "Directory", #dir_lines - 1, 0, -1)

  -- Move cursor to the last directory
  api.nvim_win_set_cursor(main_win, { #dir_lines, 0 })

  api.nvim_buf_set_keymap(buf, "n", "q", "", {
    noremap = true,
    silent = true,
    callback = function()
      close_both()
    end,
  })

  api.nvim_buf_set_keymap(buf, "n", "k", "<cmd>lua require('trident.navigator').move_up()<CR>", {
    noremap = true,
    silent = true,
  })

  api.nvim_buf_set_keymap(buf, "n", "j", "<cmd>lua require('trident.navigator').move_down()<CR>", {
    noremap = true,
    silent = true,
  })

  api.nvim_buf_set_keymap(buf, "n", "<CR>", "<cmd>lua require('trident.navigator').open_terminal_with_selection()<CR>", {
    noremap = true,
    silent = true,
  })
end

return M
