-- Claude Code integration — ENTERPRISE ONLY.
--
-- This plugin only loads when `claude-work --check` succeeds. That wrapper (installed to
-- ~/.local/bin by install.sh) verifies that a Claude Code managed policy pinning your company's
-- organization (`forceLoginOrgUUID`) is present in the Windows registry (HKLM or HKCU) or a
-- managed-settings.json file. With that policy, Claude Code itself refuses personal claude.ai
-- logins and ANTHROPIC_API_KEY / apiKeyHelper credentials. See REVIEW.md for the residual gaps.
--
-- The plugin itself just runs the CLI in a terminal split; it has no network code of its own.
local function enterprise_policy_present()
  if vim.fn.executable("claude-work") ~= 1 then
    return false
  end
  vim.fn.system({ "claude-work", "--check" })
  return vim.v.shell_error == 0
end

return {
  "greggh/claude-code.nvim",
  cond = enterprise_policy_present,
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for git operations
  },
  cmd = { "ClaudeCode", "ClaudeCodeContinue", "ClaudeCodeVerbose" },
  keys = {
    { "<C-,>", "<cmd>ClaudeCode<CR>", desc = "Toggle Claude Code" },
    { "<leader>CC", "<cmd>ClaudeCodeContinue<CR>", desc = "Claude Code (continue)" },
    { "<leader>CV", "<cmd>ClaudeCodeVerbose<CR>", desc = "Claude Code (verbose)" },
  },
  config = function()
    require("claude-code").setup({
      window = {
        split_ratio = 0.3,
        position = "botright",
        enter_insert = true,
        hide_numbers = true,
        hide_signcolumn = true,
        float = {
          width = "80%",
          height = "80%",
          row = "center",
          col = "center",
          relative = "editor",
          border = "rounded",
        },
      },
      refresh = {
        enable = true,
        updatetime = 100,
        timer_interval = 1000,
        show_notifications = true,
      },
      git = {
        use_git_root = true,
      },
      shell = {
        separator = '&&',
        pushd_cmd = 'pushd',
        popd_cmd = 'popd',
      },
      -- Always go through the enterprise guard wrapper, never the raw `claude` binary.
      command = "claude-work",
      command_variants = {
        continue = "--continue",
        resume = "--resume",
        verbose = "--verbose",
      },
      keymaps = {
        toggle = {
          normal = "<C-,>",
          terminal = "<C-,>",
          variants = {
            continue = "<leader>CC",
            verbose = "<leader>CV",
          },
        },
        window_navigation = true,
        scrolling = true,
      }
    })
  end
}
