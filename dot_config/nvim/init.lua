-- Set <space> as the leader key
-- See `:help mapleader`
-- NOTE: This must happen before plugins are loaded, otherwise the wrong leader
-- key will be used.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal.
vim.g.have_nerd_font = true

-- Load nvim option configuration.
require('config.options')

-- Load nvim keymap configuration.
require('config.keymaps')

-- Load nvim autocmd configuration.
require('config.autocmd')

-- Load the lazy.nvim plugin manager which will automatically load plugins from
-- the `lua/plugins/` directory.
require('config.lazy')

-- This is called a `modeline`, see `:help modeline` for more details.
-- vim: ts=2 sts=2 sw=2 et
