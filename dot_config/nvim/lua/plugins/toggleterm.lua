-- Easily display and hide a terminal window.

return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup({
      size = function(term)
        -- For floating terminals, this is width/height.
        -- For horizontal terminals, this is number of rows.
        -- Set the terminal size to a percentage of the of screen height.
        return math.floor(vim.o.lines * 0.36)
      end,

      direction = 'horizontal',

      -- Keymap configuration, toggle with Alt+h.
      open_mapping = '<A-h>',

      -- Hide number column.
      hide_numbers = true,

      -- Shade filetypes.
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = 2,

      -- Start insert mode when opening.
      start_in_insert = true,

      -- Terminal highlights.
      terminal_mappings = true,
    })

    -- Add custom keymaps for specific terminals.
    local Terminal = require('toggleterm.terminal').Terminal

    -- Create a vertical terminal (left/right split).
    local vterm = Terminal:new({ direction = 'vertical' })
    vim.keymap.set('n', '<leader>tv', function()
      vterm:toggle()
    end, { desc = 'Toggle Vertical Terminal' })

    -- Create a floating terminal.
    local fterm = Terminal:new({ direction = 'float' })
    vim.keymap.set('n', '<leader>tf', function()
      fterm:toggle()
    end, { desc = 'Toggle Floating Terminal' })
  end,
}

-- vim: ts=2 sts=2 sw=2 et
