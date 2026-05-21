-- Active colorscheme: nord with transparent background.
-- Matches the nord palette used in tmux status bar and starship prompt.
return {
  'gbprod/nord.nvim',
  config = function()
    require("nord").setup({
      transparent = true,
    })
    vim.cmd.colorscheme("nord")
  end

}
