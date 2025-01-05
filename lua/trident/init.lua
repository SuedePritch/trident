-- init.lua
local navigator = require("trident.navigator")
local terminal = require("trident.terminal")

local M = {}

function M.setup()
  vim.api.nvim_set_keymap(
    "n",
    "<space>ft",
    "<cmd>lua require('trident').handle_ft_keymap()<CR>",
    { noremap = true, silent = true }
  )
end

function M.handle_ft_keymap()
  if #terminal.get_open_terminals() == 0 then
    navigator.create_floating_directory_navigator()
  else
    terminal.list_open_terminals()
  end
end

return M
