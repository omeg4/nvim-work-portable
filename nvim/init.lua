-- Neobruno (work edition)
-- Portable, safe-for-work derivative of ~/.config/nvim.
-- Targets Neovim 0.12.x on Windows 11 (Git Bash) but also runs on Linux/macOS.
local vim = vim
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("work.core")
