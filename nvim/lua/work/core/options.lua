local vim = vim
local opt = vim.opt

-- line numbers
opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

opt.wrap = false

opt.ignorecase = true
opt.smartcase = true

opt.cursorline = true
opt.cursorcolumn = false

opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

opt.backspace = "indent,eol,start"

-- The official nvim-win64.zip bundles win32yank.exe, so this works on Windows without extra tools.
opt.clipboard:append("unnamedplus")

opt.splitright = true
opt.splitbelow = true

opt.swapfile = false

-- Set this for toggleterm
opt.hidden = true

-- folding (nvim-ufo provides the folds, see plugins/nvim-ufo.lua)
opt.foldcolumn = "1"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

-- which-key popup delay
opt.timeout = true
opt.timeoutlen = 300

-- Built-in ftplugins (python, ruby, ...) define buffer-local ]m/[m/]]/[[ maps that would shadow the
-- treesitter-textobjects motions; turn them off globally.
vim.g.no_plugin_maps = 1

-- set this option for nvim-ts-context-commentstring
vim.g.skip_ts_context_commentstring_module = true

-- Don't let a random repo's .nvim.lua / .exrc run code on open.
opt.exrc = false
opt.secure = true
-- Modelines in untrusted files have historically been an attack vector.
opt.modeline = false
