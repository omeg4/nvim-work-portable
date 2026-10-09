-- LSP setup for Neovim 0.11+: vim.lsp.config() / vim.lsp.enable() (enabled by mason-lspconfig).
return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    "mason-org/mason-lspconfig.nvim",
  },
  config = function()
    local keymap = vim.keymap -- for conciseness

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("WorkLspKeymaps", { clear = true }),
      callback = function(ev)
        local opts = { noremap = true, silent = true, buffer = ev.buf }

        -- Group 1 -- g{}
        opts.desc = "Show LSP references"
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

        -- Group 2 -- <l>ca
        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

        -- Group 3 -- <l>r{}
        opts.desc = "Smart rename"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", "<cmd>LspRestart<CR>", opts)

        -- Group 4 -- <l>D{}
        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>DD", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>Dd", vim.diagnostic.open_float, opts)

        -- Group 5 -- [ \[\] ]d
        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)

        -- Group 6 -- Documentation hover peek
        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts)
      end,
    })

    -- used to enable autocompletion (applies to every server)
    vim.lsp.config("*", {
      capabilities = require("cmp_nvim_lsp").default_capabilities(),
    })

    -- Change the Diagnostic symbols in the sign column (gutter)
    vim.diagnostic.config({
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = " ",
          [vim.diagnostic.severity.WARN] = " ",
          [vim.diagnostic.severity.HINT] = "󰠠 ",
          [vim.diagnostic.severity.INFO] = " ",
        },
      },
    })

    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
          completion = { callSnippet = "Replace" },
          telemetry = { enable = false }, -- lua-language-server has an (opt-in) telemetry setting; pin it off
        },
      },
    })
  end,
}
