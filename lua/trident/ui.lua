local api = vim.api
local M = {}

-- Applies consistent highlights for all floating menus
function M.apply_highlights()
  vim.cmd("highlight FloatingTitle guifg=#FFD700 guibg=#1E1E2E")
  vim.cmd("highlight FloatingBorder guifg=#5F87AF guibg=#1E1E2E")
  vim.cmd("highlight FloatingNormal guibg=#1E1E2E guifg=#FFFFFF")
end

-- Creates a titled floating menu. Returns:
--   content_buf, content_win, title_win, close_both
-- 'offset' is used for consistent vertical spacing between different menus.
function M.create_titled_menu(title, lines, offset)
  M.apply_highlights()

  local width = 40
  local title_height = 1
  local row_offset = offset or 13

  -- Title Window
  local title_row = math.ceil((vim.o.lines - row_offset) / 2)
  local title_col = math.ceil((vim.o.columns - width) / 2)
  local centered_title = string.rep(" ", math.floor((width - #title) / 2)) .. title

  local title_buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(title_buf, 0, -1, false, { centered_title })
  local title_win = api.nvim_open_win(title_buf, false, {
    relative = "editor",
    width = width,
    height = title_height,
    row = title_row,
    col = title_col,
    style = "minimal",
    border = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
  })

  -- Add a small gap between title and content
  local gap = 1 -- increase this for more space
  local content_row = title_row + title_height + gap + 1
  local content_col = title_col
  local content_height = math.min(#lines, 10)

  local content_buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(content_buf, 0, -1, false, lines)
  api.nvim_buf_set_option(content_buf, "modifiable", false)

  local content_win = api.nvim_open_win(content_buf, true, {
    relative = "editor",
    width = width,
    height = content_height,
    row = content_row,
    col = content_col,
    style = "minimal",
    border = "rounded",
  })
  api.nvim_win_set_option(content_win, "winhighlight", "Normal:FloatingNormal,FloatBorder:FloatingBorder")

  -- Local function to close both windows
  local function close_both()
    if api.nvim_win_is_valid(title_win) then
      api.nvim_win_close(title_win, true)
    end
    if api.nvim_win_is_valid(content_win) then
      api.nvim_win_close(content_win, true)
    end
  end

  -- Autocmd to close one window if the other closes
  vim.cmd(string.format(
    "autocmd WinClosed %d lua pcall(vim.api.nvim_win_close, %d, true)",
    content_win, title_win
  ))
  vim.cmd(string.format(
    "autocmd WinClosed %d lua pcall(vim.api.nvim_win_close, %d, true)",
    title_win, content_win
  ))

  return content_buf, content_win, title_win, close_both
end

return M
