-- Useful plugin to show you pending keybindings.

return {
  'folke/which-key.nvim',
  event = 'VimEnter',
  ---@module 'which-key'
  ---@type wk.Opts
  ---@diagnostic disable-next-line: missing-fields
  opts = {
    -- Configure the delay between pressing a key and opening which-key
    -- (milliseconds).
    delay = 0,
    icons = { mappings = vim.g.have_nerd_font },

    -- Document existing key chains.
    spec = {
      { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
      { '<leader>t', group = '[T]oggle' },
      -- Enable gitsigns-recommended keymaps first.
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      { 'gr', group = 'LSP Actions', mode = { 'n' } },
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
