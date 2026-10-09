return {
  -- Replaces neodev.nvim (archived) and emmylua-nvim (type stubs for the nvim API).
  "folke/lazydev.nvim",
  ft = "lua",
  opts = {
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    },
  },
}
