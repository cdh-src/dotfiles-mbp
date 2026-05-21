-- Statusline. Themed to mirror the tmux status bar:
--   * fully transparent background (no filled sections)
--   * nord palette, same hex codes as tmux/dot-tmux.status.conf
--   * no separators between sections or components; whitespace only
--   * mode badge on the far left in bright accent (purple in normal mode,
--     mirroring the prompt-prefix-held color in tmux)
--
-- nvim-specific info only: cwd, branch, and filename are intentionally
-- absent because tmux (cwd, branch) and the nvim/Ghostty title bar
-- (filename) already cover them.
--
-- Layout:  [mode icon]   [+~-]   [lsp]   …   [diag]   [L:C]   [%]

-- ---- Nord palette (in sync with tmux/dot-tmux.status.conf + starship) -----
local nord = {
  bg       = 'NONE',     -- transparent
  fg       = '#d8dee9',  -- nord4
  dim      = '#4c566a',  -- nord3
  accent   = '#88c0d0',  -- nord8 (frost light blue)
  green    = '#a3be8c',  -- nord14
  yellow   = '#ebcb8b',  -- nord13
  red      = '#bf616a',  -- nord11
  purple   = '#b48ead',  -- nord15
  orange   = '#d08770',  -- nord12
}

-- ---- Custom transparent theme --------------------------------------------
-- Mode-aware colors for section A (mode badge); everything else uses the same
-- transparent style so the bar reads as plain text on the nvim background.
local function mode(fg)
  return {
    a = { fg = fg,       bg = nord.bg, gui = 'bold' },
    b = { fg = nord.fg,  bg = nord.bg },
    c = { fg = nord.fg,  bg = nord.bg },
    x = { fg = nord.fg,  bg = nord.bg },
    y = { fg = nord.fg,  bg = nord.bg },
    z = { fg = fg,       bg = nord.bg, gui = 'bold' },
  }
end
local theme = {
  normal   = mode(nord.purple),  -- matches starship success_symbol color
  insert   = mode(nord.green),
  visual   = mode(nord.yellow),
  replace  = mode(nord.red),
  command  = mode(nord.accent),
  inactive = mode(nord.dim),
}

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    -- Force the StatusLine bg to NONE so lualine's transparent sections
    -- aren't framed by an opaque statusline background. Re-fired on every
    -- ColorScheme event because most themes (including nord.nvim with
    -- transparent=true) still set a non-empty StatusLine background.
    local function clear_statusline_bg()
      vim.api.nvim_set_hl(0, 'StatusLine',   { bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'StatusLineNC', { bg = 'NONE' })
    end
    clear_statusline_bg()
    vim.api.nvim_create_autocmd('ColorScheme', { callback = clear_statusline_bg })

    require('lualine').setup {
      options = {
        theme = theme,
        section_separators = '',
        component_separators = '',
        globalstatus = true,
        disabled_filetypes = { statusline = { 'neo-tree' } },
      },
      sections = {
        -- Mode badge + filetype icon, glued together (no separators anywhere).
        lualine_a = {
          { 'mode', fmt = function(s) return s:lower() end },
          {
            'filetype',
            icon_only = true,
            padding = { left = 1, right = 0 },
          },
        },
        -- Diff line-count summary (reads from gitsigns).
        -- Branch name is intentionally omitted; tmux shows it.
        lualine_b = {
          {
            'diff',
            source = 'gitsigns',
            symbols = { added = '+', modified = '~', removed = '-' },
            diff_color = {
              added    = { fg = nord.green },
              modified = { fg = nord.yellow },
              removed  = { fg = nord.red },
            },
          },
        },
        -- LSP status only. Filename intentionally omitted: nvim's own
        -- window title (and Ghostty's via OSC 2) covers it.
        lualine_c = {
          { 'lsp_status', color = { fg = nord.dim } },
        },
        -- Right side, in order: diagnostics, location, progress.
        lualine_x = {
          {
            'diagnostics',
            sources = { 'nvim_lsp' },
            symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
            diagnostics_color = {
              error = { fg = nord.red },
              warn  = { fg = nord.yellow },
              info  = { fg = nord.accent },
              hint  = { fg = nord.dim },
            },
          },
        },
        lualine_y = {
          { 'location', color = { fg = nord.fg } },
        },
        lualine_z = {
          { 'progress', color = { fg = nord.accent, gui = 'bold' } },
        },
      },
      -- When the window is not focused (split / unfocused tab), grey everything.
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {},
        lualine_x = { { 'location', color = { fg = nord.dim } } },
        lualine_y = {},
        lualine_z = {},
      },
    }
  end
}
