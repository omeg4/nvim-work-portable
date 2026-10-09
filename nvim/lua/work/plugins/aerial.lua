return {
  -- The personal config passed indent-blankline v2 options to aerial (they were ignored).
  -- This is a minimal, valid aerial setup; symbols-outline.nvim (archived) is replaced by it.
  "stevearc/aerial.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
  keys = {
    { "<leader>a", "<cmd>AerialToggle!<CR>", desc = "Toggle [a]erial symbol outline" },
  },
  opts = {
    backends = { "lsp", "treesitter", "markdown", "man" },
    attach_mode = "global",
  },
}
