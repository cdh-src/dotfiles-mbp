-- Syntax-aware parsing & highlighting. Auto-installs the listed grammars.
-- Lazy=false so highlighting is ready at startup.
return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "lua",
        "python",
        "vim",
        "vimdoc",
        "query",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.config").setup(opts)
    end,
}
