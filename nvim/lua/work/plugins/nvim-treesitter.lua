-- nvim-treesitter `main` branch (the `master` branch does not support Neovim 0.12).
-- Parsers are compiled locally into stdpath("data")/site with `tree-sitter build`, which needs
-- the tree-sitter CLI (>= 0.26.1) and a C compiler. install.sh provides both in user space.
-- Without them Neovim still highlights its bundled languages (c, lua, markdown, query, vim, vimdoc).
local parsers = {
  "json",
  "javascript",
  "typescript",
  "tsx",
  "yaml",
  "html",
  "css",
  "prisma",
  "markdown",
  "markdown_inline",
  "svelte",
  "graphql",
  "bash",
  "lua",
  "vim",
  "vimdoc",
  "dockerfile",
  "gitignore",
  "query",
  "python",
  "latex",
  "regex",
}

-- Filetypes where treesitter indent is preferred over the built-in indent scripts
local indent_fts = { "javascript", "typescript", "typescriptreact", "javascriptreact", "lua", "python", "html", "css", "svelte" }

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false, -- main branch does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      -- No `auto_install`: parsers are native code compiled from third-party repos, so only
      -- the explicit list above is installed. Add languages here (or :TSInstall <lang>) deliberately.
      vim.g.work_ts_parsers = parsers
      -- In interactive sessions, install any missing parsers in the background.
      -- (install.sh does the first, blocking install headlessly.)
      if vim.fn.executable("tree-sitter") == 1 and #vim.api.nvim_list_uis() > 0 then
        ts.install(parsers)
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("WorkTreesitter", { clear = true }),
        callback = function(args)
          if not pcall(vim.treesitter.start, args.buf) then
            return -- no parser for this filetype
          end
          if vim.tbl_contains(indent_fts, vim.bo[args.buf].filetype) then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })

      -- NOTE: the master-branch `incremental_selection` module (<C-n>/<C-s>/<C-p>) does not exist
      -- on `main`. See `:h treesitter` in your Neovim version for built-in node selection.
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    opts = { enable_autocmd = false },
  },
}
