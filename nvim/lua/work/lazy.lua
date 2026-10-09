local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { import = "work.plugins" },
}, {
  -- lazy-lock.json is committed with this config: `Lazy install` checks out the pinned commits.
  -- Update deliberately with `:Lazy update`, review the diff of lazy-lock.json, then commit it.
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  checker = {
    enabled = false, -- no background polling of GitHub; updates are a deliberate act
  },
  change_detection = {
    notify = false,
  },
  -- No luarocks: avoids pulling a Lua build toolchain + arbitrary rocks onto the work machine.
  rocks = {
    enabled = false,
  },
  install = {
    colorscheme = { "duskfox", "habamax" },
  },
})
