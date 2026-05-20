-- Package manager for LSP servers, formatters, linters, DAP adapters.
-- Adds the ghostty-ls registry for Ghostty config file support.
return
{
  'mason-org/mason.nvim',
  opts = {
    registries = {
      "github:mason-org/mason-registry",
      "github:mkindberg/ghostty-ls"
    }
  }
}
