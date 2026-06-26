vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.termguicolors = true

-- Load the lazy.nvim configuration
require("config.lazy")


-- MANUAL FORMATTING: Press 'Space + f' to format the current file
vim.keymap.set('n', '<leader>F', function()
  vim.lsp.buf.format({ async = true })
  print("File formatted.")
end, { desc = 'Manually Format File' })

--- Don't search only by case
vim.opt.ignorecase = true
vim.opt.smartcase = true
