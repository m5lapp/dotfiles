-- Neo-tree is a Neovim plugin to browse the file system and other tree like
-- structures in whatever style suits you.
-- See https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  enabled = false,
  branch = 'v3.x',
  -- neo-tree will lazily load itself.
  lazy = false,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    -- Optional, but recommended.
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    vim.keymap.set('n', '<C-n>', ':Neotree toggle<CR>', { desc = 'neo-tree toggle window' })
  end,
}

-- vim: ts=2 sts=2 sw=2 et
