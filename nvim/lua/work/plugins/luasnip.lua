return {
  "L3MON4D3/LuaSnip",
  version = "v2.*",
  -- jsregexp (optional; only needed for regex snippet transformations) needs make + a C compiler.
  build = (vim.fn.executable("make") == 1 and vim.fn.has("win32") == 0) and "make install_jsregexp" or nil,
}
