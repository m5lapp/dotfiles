-- [[ Basic Autocommands ]]
-- See `:help lua-guide-autocommands`

-- Automatically close unmodified, open buffers when there's more than ten open
-- and they lose focus.
vim.api.nvim_create_autocmd('BufLeave', {
  callback = function()
    if vim.fn.winnr('$') > 1 then
      return
    end

    if #vim.api.nvim_list_bufs() > 10 then
      vim.cmd('silent! bdelete')
    end
  end,
})

-- Highlight when yanking (copying) text. Try it with `yap` in normal mode.
--   See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- vim: ts=2 sts=2 sw=2 et
