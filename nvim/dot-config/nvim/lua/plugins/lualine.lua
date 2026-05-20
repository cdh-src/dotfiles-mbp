-- Statusline. Themed nord to match tmux/starship.
-- Sections: filetype/filename/lsp_status/searchcount on the left,
-- buffer list + encoding + fileformat on the right.
return {
  "nvim-lualine/lualine.nvim",
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('lualine').setup {
      options = {
        theme = 'nord',
        section_separators = { left = '', right = '' },
        --component_separators = { left = '', right = '' ,
        -- section_separators = { left = '', right = '' },
        component_separators = { left = '⏽', right = '⏽' },
        globalstatus = true,
      },
      sections = {
        lualine_c = {
          'filetype',
          'filename',
          'lsp_status',
          'searchcount',
        },
        lualine_x = {
          {
            'buffers',
            mode = 4,
            buffer_color = {
              active = 'lualine_{section}_normal',
              inactive = 'lualine_{section}_inactive',
            }
          },
          'encoding',
          'fileformat',
        }
      }
    }
  end
}
