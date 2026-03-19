-- Catppuccin colour scheme.
-- https://github.com/catppuccin/nvim

return {
  {
    'catppuccin/nvim',
    enabled = true,
    lazy = false,
    priority = 1000,
    config = function()
      require('catppuccin').setup({
        styles = {
          comments = {},
        },
      })

      -- Load the colour scheme here. Like other themes, this one has different
      -- styles you can load such as 'catppuccin-frappe', 'catppuccin-latte',
      -- 'catppuccin-macchiato', 'catppuccin-mocha'.
      vim.cmd.colorscheme('catppuccin-mocha')
    end,
  },
  {
    'miikanissi/modus-themes.nvim',
    enabled = false,
    lazy = false,
    priority = 1000,
    config = function()
      require('modus-themes').setup({
        styles = {
          comments = { italic = false },
        },
      })

      -- vim.cmd.colorscheme('modus_vivendi')
    end,
  },
  {
    'wtfox/jellybeans.nvim',
    enabled = false,
    lazy = false,
    priority = 1000,
    config = function()
      require('jellybeans').setup({
        styles = {
          comments = { italics = false },
        },
      })

      -- vim.cmd.colorscheme('jellybeans')
    end,
  },
}

-- vim: ts=2 sts=2 sw=2 et
