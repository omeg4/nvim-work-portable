-- Only loaded when WORK_NOTES_VAULT points at an existing directory (set it in ~/.bashrc.local).
-- Keep work notes in a work-sanctioned location; don't point this at a personally-synced vault.
local vault = vim.env.WORK_NOTES_VAULT

return {
  "epwalsh/obsidian.nvim",
  version = "*",
  cond = vault ~= nil and vim.fn.isdirectory(vim.fn.expand(vault)) == 1,
  ft = "markdown",
  cmd = { "ObsidianNew", "ObsidianToday", "ObsidianQuickSwitch", "ObsidianSearch", "ObsidianWorkspace" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "hrsh7th/nvim-cmp",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    vim.opt.conceallevel = 2

    require("obsidian").setup({
      wiki_link_func = function(opts)
        if opts.label ~= opts.path then
          return string.format("[[%s|%s]]", opts.path, opts.label)
        else
          return string.format("[[%s]]", opts.path)
        end
      end,
      workspaces = {
        { name = "work", path = vim.fn.expand(vault) },
      },
      completion = {
        nvim_cmp = true,
        min_chars = 2,
      },
      mappings = {
        ["gf"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
        ["<leader>ch"] = {
          action = function()
            return require("obsidian").util.toggle_checkbox()
          end,
          opts = { buffer = true },
        },
      },
      new_notes_location = "current_dir",
      daily_notes = {
        folder = "dailies",
        date_format = "%Y-%m-%d",
        alias_format = "%B %-d, %Y",
      },
      templates = {
        subdir = "Templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
      },
      use_advanced_uri = false, -- don't require the Obsidian desktop app / community plugin
      open_app_foreground = false,
      sort_by = "modified",
      sort_reversed = true,
      open_notes_in = "hsplit",
      ui = {
        enable = true,
        update_debounce = 200,
      },
      attachments = {
        img_folder = "attach",
      },
      note_id_func = function(title)
        local suffix = ""
        if title ~= nil then
          suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        else
          for _ = 1, 4 do
            suffix = suffix .. string.char(math.random(65, 90))
          end
        end
        return tostring(os.time()) .. "-" .. suffix
      end,
      follow_url_func = function(url)
        vim.ui.open(url) -- cross-platform replacement for xdg-open
      end,
    })

    require("which-key").add({
      { "<leader>o", group = "Obsidian.nvim" },
      { "<leader>of", "<cmd>ObsidianFollowLink<CR>", desc = "Follow Obsidian Link" },
      { "<leader>og", "<cmd>ObsidianFollowLink vsplit<CR>", desc = "Follow Obsidian Link (vsplit)" },
      { "<leader>ov", "<cmd>ObsidianFollowLink hsplit<CR>", desc = "Follow Obsidian Link (hsplit)" },
      { "<leader>olb", "<cmd>ObsidianBacklinks<CR>", desc = "List [B]acklinks to current note/buffer" },
      { "<leader>oll", "<cmd>ObsidianLink<CR>", desc = "[L]ink inline selection to existing note" },
      { "<leader>oln", "<cmd>ObsidianLinkNew<CR>", desc = "[N]ew note linked to inline selection" },
      { "<leader>on", "<cmd>ObsidianNew<CR>", desc = "Open Obsidian New" },
      { "<leader>oo", "<cmd>ObsidianToday<CR>", desc = "Open Obsidian Today" },
      { "<leader>oq", "<cmd>ObsidianQuickSwitch<CR>", desc = "Open Obsidian Quick Switch" },
      { "<leader>ot", "<cmd>ObsidianTemplate<CR>", desc = "Insert Obsidian [T]emplate" },
    })
  end,
}
