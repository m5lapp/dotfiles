local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require("lspconfig")
local util = require "lspconfig/util"

-- For multiple LSPs, they can be set up in a loop as described at:
-- --https://nvchad.com/docs/config/lsp
lspconfig.gopls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = {"gopls"},
  filetypes = { "go", "gomod", "gotmpl", "gowork" },
  root_dir = util.root_pattern(".git", "go.mod", "go.work"),
  settings = {
    gopls = {
      -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
      completeUnimported = true,
      usePlaceholders = true,
      analyses = {
        -- https://github.com/golang/tools/blob/master/gopls/doc/analyzers.md
        unusedParams = true,
      },
    },
  },
}

