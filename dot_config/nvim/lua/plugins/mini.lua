-- mini.nvim - A collection of various small independent plugins/modules.
--   https://github.com/nvim-mini/mini.nvim

return {
  'nvim-mini/mini.nvim',
  config = function()
    -- Better Around/Inside textobjects, for example:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup({ n_lines = 500 })

    -- Add/delete/replace surroundings (brackets, quotes, etc.), for example:
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup()
  end,
}

-- vim: ts=2 sts=2 sw=2 et
