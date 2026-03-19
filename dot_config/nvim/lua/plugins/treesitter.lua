-- Highlight, edit, and navigate code.

return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  branch = 'main',
  opts = {
    ensure_installed = {
      'json', -- Data formats
      'proto',
      'yaml',
      'sql', -- Databases
      'latex', -- Documents
      'markdown',
      'git_config', -- Git
      'gitcommit',
      'gitignore',
      'go', -- Go
      'gomod',
      'gosum',
      'lua', -- Lua
      'terraform', -- Infrastructure
      'python', -- Python
      'bash', -- Systems
      'cmake',
      'html', -- Web development
      'http',
      'javascript',
    },
  },
  -- Configure Treesitter, see `:help nvim-treesitter-intro`.
  config = function()
    local parsers = {
      'bash',
      'c',
      'diff',
      'html',
      'lua',
      'luadoc',
      'markdown',
      'markdown_inline',
      'query',
      'vim',
      'vimdoc',
    }
    require('nvim-treesitter').install(parsers)
    vim.api.nvim_create_autocmd('FileType', {
      callback = function(args)
        local buf, filetype = args.buf, args.match

        local language = vim.treesitter.language.get_lang(filetype)
        if not language then
          return
        end

        -- Check if parser exists and load it.
        if not vim.treesitter.language.add(language) then
          return
        end
        -- Enable syntax highlighting and other treesitter features.
        vim.treesitter.start(buf, language)

        -- Enables treesitter based folds.
        -- for more info on folds see `:help folds`
        -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        -- vim.wo.foldmethod = 'expr'

        -- Enable treesitter based indentation.
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}

-- vim: ts=2 sts=2 sw=2 et
