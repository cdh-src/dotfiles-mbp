return
{
  'neovim/nvim-lspconfig',
  config = function()
    -- 1. Global configuration (applied to all servers)
    vim.lsp.config("*", {
      capabilities = require('cmp_nvim_lsp').default_capabilities(),
    })

    -- 2. Define or override specific server settings.
    -- Note: nvim-lspconfig still provides the defualts.
    vim.lsp.config("pyright", {
      settings = {
        python = { analysis = { autoSearchPaths = true} }
      }
    })

    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          runtime = {
            version = 'LuaJIT',
          },
          diagnostics = {
            globals = { 'vim' },
          },
          workspace = {
            library = {
              vim.env.VIMRUNTIME,
              -- This adds your own config and plugins to the path.
              -- "${3rd}/luv/library" -- optional: for libuv help?
            },
            checkThirdParty = false, -- Stops "do you want" popups.
          },
          telemetry = { enable = false },
        },
      },
    })

    -- 3. Enable the servers.
    vim.lsp.enable("pyright")
    vim.lsp.enable("lua_ls")
  end
}

