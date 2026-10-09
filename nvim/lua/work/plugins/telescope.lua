-- telescope-fzf-native is a C extension. Build it with whatever is available:
-- `make` (w64devkit / Linux), else plain gcc. If neither exists telescope falls back to its Lua sorter.
local function fzf_build()
  if vim.fn.executable("make") == 1 then
    return "make"
  end
  if vim.fn.executable("gcc") == 1 then
    local ext = vim.fn.has("win32") == 1 and "dll" or "so"
    return "mkdir -p build && gcc -O3 -Wall -fpic -std=gnu99 -shared src/fzf.c -o build/libfzf." .. ext
  end
  return nil
end

return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = fzf_build(),
      cond = fzf_build() ~= nil,
    },
    "nvim-tree/nvim-web-devicons",
    "folke/trouble.nvim",
  },
  cmd = "Telescope",
  config = function()
    local trouble = require("trouble.sources.telescope")
    local actions = require("telescope.actions")
    local telescope = require("telescope")

    telescope.setup({
      defaults = {
        path_display = { "truncate" },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous, -- move to prev result
            ["<C-j>"] = actions.move_selection_next, -- move to next result
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            ["<C-t>"] = trouble.open,
            ["<C-v>"] = actions.file_split,
            ["<C-i>"] = actions.file_vsplit,
          },
          n = {
            ["<C-t>"] = trouble.open,
            ["<C-v>"] = actions.file_split,
            ["<C-i>"] = actions.file_vsplit,
          },
        },
      },
      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown({}),
        },
      },
    })

    pcall(telescope.load_extension, "fzf")
  end,
}
