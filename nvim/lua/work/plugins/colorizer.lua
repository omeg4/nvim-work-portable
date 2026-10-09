return {
  -- Repo moved from NvChad/nvim-colorizer.lua; use the canonical location.
  "catgoose/nvim-colorizer.lua",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    filetypes = { "*" },
    user_default_options = {
      names = false,
      hsl_fn = true,
      RRGGBBAA = true,
      rgb_fn = true,
    },
  },
}
