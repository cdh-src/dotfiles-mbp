-- Makes LSP-aware file moves/renames (in neo-tree) update imports/refs.
-- Note: also declared inside neo-tree.lua; lazy.nvim merges the specs.
return {
  "antosha417/nvim-lsp-file-operations",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-neo-tree/neo-tree.nvim",
  },
  config = function()
    require("lsp-file-operations").setup()
  end,
}
