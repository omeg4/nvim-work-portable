return {
  -- Also replaces dressing.nvim (archived upstream) for vim.ui.select.
  "nvim-telescope/telescope-ui-select.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  event = "VeryLazy",
  config = function()
    require("telescope").load_extension("ui-select")
  end,
}
