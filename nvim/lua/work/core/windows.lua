-- Windows-only tweaks. Everything here is skipped on Linux/macOS.
local vim = vim
if vim.fn.has("win32") ~= 1 then
  return
end

-- Use Git Bash as Neovim's shell (`:!`, `:terminal`, toggleterm, claude-code.nvim, lazy build steps).
-- The default on Windows is cmd.exe, which can't run the bash wrapper scripts this setup installs.
-- Set NVIM_KEEP_CMD=1 to opt out if a plugin misbehaves.
local bash = vim.fn.exepath("bash")
if bash ~= "" and vim.env.NVIM_KEEP_CMD == nil then
  vim.o.shell = bash
  vim.o.shellcmdflag = "-c"
  vim.o.shellredir = ">%s 2>&1"
  vim.o.shellpipe = "2>&1 | tee"
  vim.o.shellquote = ""
  vim.o.shellxquote = ""
  vim.o.shellxescape = ""
end

-- Parsers built by nvim-treesitter are .dll files; make sure the C compiler installed by
-- install.sh (w64devkit gcc) is used if no other compiler is configured.
if vim.env.CC == nil and vim.fn.executable("gcc") == 1 then
  vim.env.CC = "gcc"
end
