-- Package manager for LSP servers, formatters, linters, DAP adapters.
-- Adds the ghostty-ls registry for Ghostty config file support.
--
-- mason-lspconfig pulls in the servers nvim-lspconfig.lua enables so a fresh
-- install (host or container) gets LSPs without a manual :MasonInstall.
return {
  {
    'mason-org/mason.nvim',
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        "github:mkindberg/ghostty-ls"
      }
    }
  },
  {
    'mason-org/mason-lspconfig.nvim',
    dependencies = { 'mason-org/mason.nvim' },
    opts = {
      ensure_installed = { 'pyright', 'lua_ls', 'yamlls' },
      automatic_installation = false,
    },
  },
}
