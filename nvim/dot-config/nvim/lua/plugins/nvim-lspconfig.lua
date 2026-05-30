-- Built-in LSP client config. Enables pyright, emmylua_ls, yamlls, jsonls.
-- Wires nvim-cmp capabilities into all servers via the "*" config.
return {
  'neovim/nvim-lspconfig',
  dependencies = { 'b0o/SchemaStore.nvim' },
  config = function()
    -- 1. Global configuration (applied to all servers)
    vim.lsp.config("*", {
      capabilities = require('cmp_nvim_lsp').default_capabilities(),
    })

    -- 2. Define or override specific server settings.
    -- Note: nvim-lspconfig still provides the defaults.
    vim.lsp.config("pyright", {
      settings = {
        python = { analysis = { autoSearchPaths = true} }
      }
    })

    -- emmylua_ls only reads config from .emmyrc.json/.luarc.json/.emmyrc.lua
    -- at the workspace root - it ignores LSP `settings`. We generate the JSON
    -- on every startup so workspace.library picks up the current set of lazy
    -- plugins (fixes [unresolved-require] and enables completions for plugin
    -- modules and vim.*). The file is written into the real ~/.config/nvim/
    -- dir; stow symlinks individual files, not the parent dir, so the
    -- generated config stays out of the repo.
    do
      local emmyrc = {
        ["$schema"] = "https://raw.githubusercontent.com/EmmyLuaLs/emmylua-analyzer-rust/refs/heads/main/crates/emmylua_code_analysis/resources/schema.json",
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = {
          library = vim.api.nvim_get_runtime_file("", true),
        },
      }
      local path = vim.fn.stdpath("config") .. "/.emmyrc.json"
      local f = io.open(path, "w")
      if f then
        f:write(vim.json.encode(emmyrc))
        f:close()
      end
    end

    vim.lsp.config("yamlls", {
      settings = {
        yaml = {
          format = {
            enable = true,
          },
          validate = true,
          schemaStore = {
            -- Disable yamlls's built-in (stale) schemastore copy in favor of
            -- the up-to-date one bundled by SchemaStore.nvim.
            enable = false,
            url = "",
          },
          schemas = require('schemastore').yaml.schemas(),
        },
      },
    })

    vim.lsp.config("jsonls", {
      settings = {
        json = {
          schemas = require('schemastore').json.schemas(),
          validate = { enable = true },
        },
      },
    })

    -- 3. Enable the servers.
    vim.lsp.enable("pyright")
    vim.lsp.enable("emmylua_ls")
    vim.lsp.enable("yamlls")
    vim.lsp.enable("jsonls")
  end
}

