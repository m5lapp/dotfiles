local plugins = {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "json", "proto", "yaml",                 -- Data formats
        "sql",                                   -- Databases
        "latex", "markdown",                     -- Documents
        "git_config", "gitcommit", "gitignore",  -- Git
        "go", "gomod", "gosum",                  -- Go
        "python",                                -- Python
        "bash", "cmake",                         -- Systems
        "html", "http", "javascript",            -- Web development
      },
    },
  },

  {
    -- Any packages listed here can be installed with :MasonInstallAll. :Mason
    -- can be used to list all the available packages.
    -- https://nvchad.com/docs/config/lsp#mason_nvim
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "goimports",
        "golines",
        "gopls",
      },
    },
  },

  {
    -- Override the nvim-lspconfig package with a new configuration that loads
    -- in the default NvChad lspconfig and our custom lspconfig.
    "neovim/nvim-lspconfig",
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end,
  },

  {
    "airblade/vim-gitgutter",
    lazy = false,
  },

  {
    "jose-elias-alvarez/null-ls.nvim",
    ft = "go",
    opts = function()
      return require "custom.configs.null-ls"
    end,
  },

  {
    "olexsmir/gopher.nvim",
    ft = "go",
    config = function(_, opts)
      require("gopher").setup(opts)
    end,
    build = function()
      vim.cmd [[silent! GoInstallDeps]]
    end,
  },
}

return plugins

