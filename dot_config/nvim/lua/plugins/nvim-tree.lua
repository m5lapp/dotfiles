return {
  'nvim-tree/nvim-tree.lua',
  version = 'v1',
  -- nvim-tree will lazily load itself.
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('nvim-tree').setup({
      filters = {
        -- `true` here means that the file types will be filtered out (hidden).
        dotfiles = false,
        git_ignored = false,
      },
      view = {
        width = 30,
      },
    })
    vim.keymap.set('n', '<C-n>', '<cmd>NvimTreeToggle<CR>', { desc = 'nvimtree toggle window' })
    vim.keymap.set('n', '<leader>e', '<cmd>NvimTreeFocus<CR>', { desc = 'nvimtree focus window' })
  end,
}

-- vim: ts=2 sts=2 sw=2 et
