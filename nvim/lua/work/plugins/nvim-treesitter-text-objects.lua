-- nvim-treesitter-textobjects `main` branch: configuration via setup(), mappings via vim.keymap.
return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  branch = "main",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("nvim-treesitter-textobjects").setup({
      select = {
        -- Automatically jump forward to textobj, similar to targets.vim
        lookahead = true,
      },
      move = {
        set_jumps = true, -- whether to set jumps in the jumplist
      },
    })

    local select = require("nvim-treesitter-textobjects.select")
    local swap = require("nvim-treesitter-textobjects.swap")
    local move = require("nvim-treesitter-textobjects.move")

    local selects = {
      ["a="] = { "@assignment.outer", "Select outer part of an assignment" },
      ["i="] = { "@assignment.inner", "Select inner part of an assignment" },
      ["l="] = { "@assignment.lhs", "Select left hand side of an assignment" },
      ["r="] = { "@assignment.rhs", "Select right hand side of an assignment" },

      ["a:"] = { "@property.outer", "Select outer part of an object property" },
      ["i:"] = { "@property.inner", "Select inner part of an object property" },
      ["l:"] = { "@property.lhs", "Select left part of an object property" },
      ["r:"] = { "@property.rhs", "Select right part of an object property" },

      ["aa"] = { "@parameter.outer", "Select outer part of a parameter/argument" },
      ["ia"] = { "@parameter.inner", "Select inner part of a parameter/argument" },

      ["ai"] = { "@conditional.outer", "Select outer part of a conditional" },
      ["ii"] = { "@conditional.inner", "Select inner part of a conditional" },

      ["al"] = { "@loop.outer", "Select outer part of a loop" },
      ["il"] = { "@loop.inner", "Select inner part of a loop" },

      ["af"] = { "@call.outer", "Select outer part of a function call" },
      ["if"] = { "@call.inner", "Select inner part of a function call" },

      ["am"] = { "@function.outer", "Select outer part of a method/function definition" },
      ["im"] = { "@function.inner", "Select inner part of a method/function definition" },

      ["ac"] = { "@class.outer", "Select outer part of a class" },
      ["ic"] = { "@class.inner", "Select inner part of a class" },
    }
    for lhs, spec in pairs(selects) do
      vim.keymap.set({ "x", "o" }, lhs, function()
        select.select_textobject(spec[1], "textobjects")
      end, { desc = spec[2] })
    end

    -- Swaps moved from <leader>n* / <leader>p* (they collided with the noice and
    -- plugin-management groups) to <leader>x{n,p}* ("e[x]change").
    local swaps = {
      ["<leader>xna"] = { "swap_next", "@parameter.inner", "Swap parameter with next" },
      ["<leader>xn:"] = { "swap_next", "@property.outer", "Swap object property with next" },
      ["<leader>xnm"] = { "swap_next", "@function.outer", "Swap function with next" },
      ["<leader>xpa"] = { "swap_previous", "@parameter.inner", "Swap parameter with previous" },
      ["<leader>xp:"] = { "swap_previous", "@property.outer", "Swap object property with previous" },
      ["<leader>xpm"] = { "swap_previous", "@function.outer", "Swap function with previous" },
    }
    for lhs, spec in pairs(swaps) do
      vim.keymap.set("n", lhs, function()
        swap[spec[1]](spec[2])
      end, { desc = spec[3] })
    end

    local moves = {
      goto_next_start = {
        ["]f"] = { "@call.outer", "Next function call start" },
        ["]m"] = { "@function.outer", "Next method/function def start" },
        ["]c"] = { "@class.outer", "Next class start" },
        ["]i"] = { "@conditional.outer", "Next conditional start" },
        ["]l"] = { "@loop.outer", "Next loop start" },
        ["]s"] = { "@local.scope", "Next scope", "locals" },
        ["]z"] = { "@fold", "Next fold", "folds" },
      },
      goto_next_end = {
        ["]F"] = { "@call.outer", "Next function call end" },
        ["]M"] = { "@function.outer", "Next method/function def end" },
        ["]C"] = { "@class.outer", "Next class end" },
        ["]I"] = { "@conditional.outer", "Next conditional end" },
        ["]L"] = { "@loop.outer", "Next loop end" },
      },
      goto_previous_start = {
        ["[f"] = { "@call.outer", "Prev function call start" },
        ["[m"] = { "@function.outer", "Prev method/function def start" },
        ["[c"] = { "@class.outer", "Prev class start" },
        ["[i"] = { "@conditional.outer", "Prev conditional start" },
        ["[l"] = { "@loop.outer", "Prev loop start" },
      },
      goto_previous_end = {
        ["[F"] = { "@call.outer", "Prev function call end" },
        ["[M"] = { "@function.outer", "Prev method/function def end" },
        ["[C"] = { "@class.outer", "Prev class end" },
        ["[I"] = { "@conditional.outer", "Prev conditional end" },
        ["[L"] = { "@loop.outer", "Prev loop end" },
      },
    }
    for fn, maps in pairs(moves) do
      for lhs, spec in pairs(maps) do
        vim.keymap.set({ "n", "x", "o" }, lhs, function()
          move[fn](spec[1], spec[3] or "textobjects")
        end, { desc = spec[2] })
      end
    end

    -- NOTE: the personal config remapped `,` / `<C-,>` to repeat_last_move and made f/F/t/T
    -- repeatable. That clobbered the `,` Hop group and the claude-code `<C-,>` toggle, so it is
    -- left out here.
  end,
}
