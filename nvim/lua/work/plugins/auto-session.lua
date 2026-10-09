return {
  "rmagatti/auto-session",
  lazy = false,
  config = function()
    ---@diagnostic disable: missing-fields
    require("auto-session").setup({
      auto_restore = true,
      suppressed_dirs = { "~/", "~/Downloads", "~/Documents", "~/Desktop/" },
    })

    local keymap = vim.keymap
    keymap.set("n", "<leader>sr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" })
    keymap.set("n", "<leader>ss", "<cmd>SessionSave<CR>", { desc = "Save session for auto session root dir" })
  end,
}
