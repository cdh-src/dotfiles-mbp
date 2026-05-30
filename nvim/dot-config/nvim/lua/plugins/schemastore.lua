-- Bundles the schemastore.org JSON Schema catalog and feeds it to jsonls
-- and yamlls (see nvim-lspconfig.lua). Lazy-loaded; required on demand.
return { "b0o/SchemaStore.nvim", lazy = true, version = false }
