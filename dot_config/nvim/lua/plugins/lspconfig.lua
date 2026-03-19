-- LSP plugins.

return {
  -- Main LSP Configuration.
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Automatically install LSPs and related tools to stdpath for Neovim. Mason
    -- must be loaded before its dependents so we need to set it up here.
    -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`.
    {
      'mason-org/mason.nvim',
      ---@module 'mason.settings'
      ---@type MasonSettings
      ---@diagnostic disable-next-line: missing-fields
      opts = {},
    },
    -- Maps LSP server names between nvim-lspconfig and Mason package names.
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    -- Useful status updates for LSP.
    { 'j-hui/fidget.nvim', opts = {} },
  },
  config = function()
    --  This function gets run when an LSP attaches to a particular buffer. That
    --  is to say, every time a new file is opened that is associated with an
    --  LSP (for example, opening `main.go` is associated with `gopls`) this
    --  function will be executed to configure the current buffer.
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        -- Create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description each
        -- time.
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        -- Rename the variable underneath the cursor. Most Language Servers
        -- support renaming across files, etc.
        map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

        -- Execute a code action, usually the cursor needs to be on top of an
        -- error or a suggestion from the LSP for this to activate.
        map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

        -- WARN: This is not Goto Definition, this is Goto Declaration. For
        -- example, in C this would take you to the header.
        map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        -- The following two autocommands are used to highlight references of
        -- the word underneth the cursor when the cursor rests there for a
        -- little while. When you move the cursor, the highlights will be
        -- cleared (the second autocommand).
        --
        -- See `:help CursorHold` for information about when this is executed.
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method('textDocument/documentHighlight', event.buf) then
          local highlight_augroup =
            vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })

          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds({ group = 'kickstart-lsp-highlight', buffer = event2.buf })
            end,
          })
        end

        -- The following code creates a keymap to toggle inlay hints in your
        -- code, if the language server being used supports them. This may be
        -- unwanted, since they displace some of your code.
        if client and client:supports_method('textDocument/inlayHint', event.buf) then
          local toggle_inlay_hint = function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
          end
          map('<leader>th', toggle_inlay_hint, '[T]oggle Inlay [H]ints')
        end
      end,
    })

    -- Enable the following language servers to automatically be installed. See
    -- `:help lsp-config` for information about keys and how to configure them.
    ---@type table<string, vim.lsp.Config>
    local servers = {
      gopls = {
        settings = {
          -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
          gopls = {
            analyses = {
              -- https://github.com/golang/tools/blob/master/gopls/doc/analyzers.md
              unusedparams = true,
              shadow = true,
            },
            staticcheck = true,
            usePlaceholders = true,
            completeUnimported = true,
            deepCompletion = true,
          },
        },
      },
      -- pyright = {},
      -- rust_analyzer = {},
      --
      -- Some languages (like typescript) have entire language plugins that can be useful:
      --    https://github.com/pmizio/typescript-tools.nvim
      --
      -- But for many setups, the LSP (`ts_ls`) will work just fine
      -- ts_ls = {},

      -- Used to format Lua code.
      stylua = {},

      -- Special Lua Config, as recommended by the neovim help docs:
      --   https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#lua_ls
      lua_ls = {
        on_init = function(client)
          if client.workspace_folders then
            local path = client.workspace_folders[1].name

            if
              path ~= vim.fn.stdpath('config')
              and (
                vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')
              )
            then
              return
            end
          end

          client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
            runtime = {
              -- Tell the language server which version of Lua you're using
              -- (most likely LuaJIT in the case of Neovim).
              version = 'LuaJIT',
              -- Tell the language server how to find Lua modules same way as
              -- Neovim (see `:h lua-module-load`).
              path = { 'lua/?.lua', 'lua/?/init.lua' },
            },
            -- Make the server aware of the Neovim runtime files.
            workspace = {
              checkThirdParty = false,
              -- Pull in all of the 'runtimepath'.
              -- NOTE: this is a lot slower and will cause issues when working
              -- on your own configuration. See:
              --   https://github.com/neovim/nvim-lspconfig/issues/3189
              library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
                -- Add additional paths.
                '${3rd}/luv/library',
                '${3rd}/busted/library',
              }),
            },
          })
        end,
        settings = {
          Lua = {},
        },
      },
    }

    -- Ensure the servers and tools above are installed.
    --
    -- To check the current status of installed tools and/or manually install
    -- other tools, you can run `:Mason`
    --
    -- You can press `g?` for help in this menu.
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      -- You can add other tools here that you want Mason to install.
      'lua-language-server',
      'stylua',
    })

    require('mason-tool-installer').setup({ ensure_installed = ensure_installed })

    for name, server in pairs(servers) do
      vim.lsp.config(name, server)
      vim.lsp.enable(name)
    end
  end,
}

-- vim: ts=2 sts=2 sw=2 et
