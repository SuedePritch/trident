local api = vim.api
local ui = require("trident.ui")
local M = {}
local open_terminals = {}

local function track_terminal_commands(buf)
  local job_id = vim.b[buf].terminal_job_id
  if not job_id then
    return
  end

  -- Capture command on <CR> in terminal mode
  api.nvim_buf_set_keymap(
    buf,
    "t",
    "<CR>",
    "<C-\\><C-n>:lua require('trident.terminal')._capture_current_command(" .. buf .. ")<CR>i<CR>",
    { noremap = true, silent = true }
  )
end

-- Called from the <CR> mapping in terminal mode
function M._capture_current_command(bufnr)
  local cursor_pos = api.nvim_win_get_cursor(0)
  local line = api.nvim_buf_get_lines(bufnr, cursor_pos[1] - 1, cursor_pos[1], false)[1]
  if not line then
    return
  end
  local command = line:gsub("^%s*[%$#>]%s*", "")
  if #command > 0 then
    for _, term in ipairs(open_terminals) do
      if term.buf == bufnr then
        term.command = command
        break
      end
    end
  end
end

-- Open the terminal after the user selects a directory
function M.open_terminal_with_selection(selected_part)
  local buf = api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.ceil((vim.o.lines - height) / 2)
  local col = math.ceil((vim.o.columns - width) / 2)

  local term = {
    buf = buf,
    dir = selected_part,
    width = width,
    height = height,
    row = row,
    col = col,
    command = "[No command yet]",
  }

  table.insert(open_terminals, term)

  api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  local shell_cmd = string.format([[
    cd /%s
    export PS1='$ '
    exec $SHELL
  ]], vim.fn.fnameescape(selected_part))

  vim.fn.termopen(shell_cmd, {
    on_exit = function()
      for i, t in ipairs(open_terminals) do
        if t.buf == buf then
          table.remove(open_terminals, i)
          break
        end
      end
    end,
  })

  track_terminal_commands(buf)

  -- Keymaps for terminal
  api.nvim_buf_set_keymap(buf, "t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })
  api.nvim_buf_set_keymap(buf, "t", "<C-q>", [[<C-\><C-n>:close<CR>]], { noremap = true, silent = true })

  vim.cmd("startinsert")
end

-- Show a list of open terminals using the same UI style
function M.list_open_terminals()
  local lines = {}
  for _, term in ipairs(open_terminals) do
    table.insert(lines, term.command or "[No command yet]")
  end
  table.insert(lines, "[+] New Terminal")

  local buf, main_win, title_win, close_both = ui.create_titled_menu(
    "Select an Active Terminal",
    lines,
    13 -- same offset as the directory navigator
  )

  -- Keymaps using callback
  api.nvim_buf_set_keymap(buf, "n", "q", "", {
    noremap = true,
    silent = true,
    callback = function()
      close_both()
    end,
  })

  api.nvim_buf_set_keymap(buf, "n", "<CR>", "<cmd>lua require('trident.terminal')._handle_term_selection()<CR>", {
    noremap = true,
    silent = true,
  })

  api.nvim_buf_set_keymap(buf, "n", "dd", "<cmd>lua require('trident.terminal')._delete_terminal()<CR>", {
    noremap = true,
    silent = true,
  })
end

function M._handle_term_selection()
  local selection = api.nvim_win_get_cursor(0)[1]
  vim.cmd("close")
  if selection <= #open_terminals then
    local term = open_terminals[selection]
    api.nvim_open_win(term.buf, true, {
      relative = "editor",
      width = term.width,
      height = term.height,
      row = term.row,
      col = term.col,
      style = "minimal",
      border = "rounded",
    })
    vim.cmd("startinsert")
  else
    require("trident.navigator").create_floating_directory_navigator()
  end
end

function M._delete_terminal()
  local selection = api.nvim_win_get_cursor(0)[1]
  if selection <= #open_terminals then
    local term = table.remove(open_terminals, selection)
    if api.nvim_buf_is_valid(term.buf) then
      api.nvim_buf_delete(term.buf, { force = true })
    end
  end
  M.list_open_terminals()
end

-- Getter for external checks
function M.get_open_terminals()
  return open_terminals
end

return M
