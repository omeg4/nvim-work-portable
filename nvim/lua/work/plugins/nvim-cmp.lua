return {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "onsails/lspkind.nvim", -- vs-code like pictograms
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer", -- source for text in buffer
    "hrsh7th/cmp-path", -- source for file system paths
    "hrsh7th/cmp-cmdline",
    "hrsh7th/cmp-nvim-lua",
    -- snippets
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip", -- for autocompletion
    "rafamadriz/friendly-snippets", -- useful snippets
    -- NOTE: codeium/windsurf and copilot-cmp sources intentionally removed (see REVIEW.md)
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local lspkind = require("lspkind")

    -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
    require("luasnip.loaders.from_vscode").lazy_load()

    ---@diagnostic disable: redundant-parameter, missing-fields
    cmp.setup({
      completion = {
        completeopt = "menu,menuone,preview,noselect",
      },
      snippet = { -- configure how nvim-cmp interacts with snippet engine
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
        ["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
        ["<C-e>"] = cmp.mapping.abort(), -- close completion window
        ["<C-l>"] = cmp.mapping.confirm({ select = false }),
      }),
      -- sources for autocompletion
      sources = cmp.config.sources({
        { name = "lazydev", group_index = 0 }, -- lua_ls completions for the nvim API
        { name = "nvim_lsp", group_index = 1 },
        { name = "nvim_lua", group_index = 3 },
        { name = "luasnip", group_index = 3 }, -- snippets
        { name = "path", group_index = 10 }, -- file system paths
        { name = "buffer", group_index = 20 }, -- text within current buffer
      }),
      -- configure lspkind for vs-code like pictograms in completion menu
      formatting = {
        format = lspkind.cmp_format({
          preset = "default",
          mode = "symbol_text",
          maxwidth = 50,
          ellipsis_char = "...",
        }),
      },
    })

    cmp.setup.cmdline("/", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = "buffer" },
      },
    })

    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = "cmdline", group_index = 1 },
        { name = "path", group_index = 2 },
      }),
    })
  end,
}
