-- A fast and easy to configure Neovim statusline.
--   https://github.com/nvim-lualine/lualine.nvim
-- The config here was inspired by:
--   https://github.com/BreadOnPenguins/nvim/blob/master/lua/plugins/lualine.lua

local branch = {
  'branch',
  icon = '',
}

local diagnostics = {
  'diagnostics',
  sources = { 'nvim_diagnostic' },
  sections = { 'error', 'warn' },
  symbols = { error = ' ', warn = ' ' },
  colored = true,
  update_in_insert = false,
  always_visible = true,
  cond = function()
    return vim.bo.filetype ~= 'markdown'
  end,
}

local diff = {
  'diff',
  colored = true,
  symbols = { added = ' ', modified = ' ', removed = ' ' },
}

local progress = function()
  local current_line = vim.fn.line('.')
  local total_lines = vim.fn.line('$')
  -- `chars` can contain an arbitrary number of icons.
  local chars = { '', '', '' }
  local line_ratio = current_line / total_lines
  local index = math.ceil(line_ratio * #chars)
  return chars[index] .. ' ' .. math.floor(line_ratio * 100) .. '%%'
end

return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('lualine').setup({
      options = {
        icons_enabled = true,
        theme = 'auto', -- `auto` allows for theme switching.
      },

      sections = {
        lualine_a = { 'mode' },
        lualine_b = { branch, diff, diagnostics },
        lualine_c = { 'filename' },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'location' },
        lualine_z = { progress },
      },

      extensions = { 'nvim-tree' },
    })
  end,
}

-- vim: ts=2 sts=2 sw=2 et
