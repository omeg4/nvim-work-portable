return {
  "numToStr/Comment.nvim",
  lazy = false,
  dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
  config = function()
    require("Comment").setup({
      ignore = "^$",
      toggler = {
        line = "<leader>cc",
        block = "<leader>cb",
      },
      opleader = {
        line = "<leader>cc",
        block = "<leader>cb",
      },
      extra = {
        above = "<leader>cO",
        below = "<leader>co",
        eol = "<leader>cA",
      },
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
    })
  end,
}
