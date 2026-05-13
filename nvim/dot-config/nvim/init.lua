require("config.lazy")

vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

vim.keymap.set('n', '<Leader>e', '<cmd>Neotree right toggle<CR>', {noremap = true, silent = true})
vim.keymap.set('n', '<Leader>xx', '<cmd>lua vim.diagnostic.open_float()<CR>', {noremap=true, silent=true})

vim.keymap.set('n', '<Leader>h', '<cmd>wincmd h<CR>', {noremap = true, silent = true})
vim.keymap.set('n', '<Leader>j', '<cmd>wincmd j<CR>', {noremap = true, silent = true})
vim.keymap.set('n', '<Leader>k', '<cmd>wincmd k<CR>', {noremap = true, silent = true})
vim.keymap.set('n', '<Leader>l', '<cmd>wincmd l<CR>', {noremap = true, silent = true})


vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "init.lua",
  callback = function()
    dofile(vim.env.MYVIMRC)
    vim.notify("NVIM configuration reloaded!", vim.log.levels.INFO)
  end,
})

--vim.cmd("colorscheme rose-pine-main")
