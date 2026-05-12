return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
    ---@module "neo-tree"
    ---@type neotree.Config?
    opts = {
      close_if_last_window = true,
      window = {
        position = "right"
      }
    }
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim",
    },
    config = function ()
      require("lsp-file-operations").setup()
    end,
  }
}
