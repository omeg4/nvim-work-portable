return {
  'MeanderingProgrammer/render-markdown.nvim',
  enabled = false, -- disabled in the personal config too; safe to enable
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {},
}
