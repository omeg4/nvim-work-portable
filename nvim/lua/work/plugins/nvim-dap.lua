return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "mfussenegger/nvim-dap-python",
    -- Removed: nvim-dap-vscode-js (unmaintained since 2023), xubury/emmylua.nvim (unlicensed,
    -- 0-star fork with an npm build step), and the Linux-only local-lua-debugger / wezterm settings.
  },
  keys = {
    { "<Leader>dc", function() require("dap").continue() end, desc = "[C]ontinue debugging" },
    { "<Leader>dt", function() require("dap").toggle_breakpoint() end, desc = "[T]oggle nvim-dap breakpoint" },
  },
  config = function()
    local dap, dapui = require("dap"), require("dapui")
    dapui.setup()

    dap.defaults.fallback.terminal_win_cmd = 'tabnew'
    dap.defaults.python.terminal_win_cmd = 'belowright new'

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end

    vim.keymap.set( "n", "<Leader>ds", dap.step_over, { desc = "[S]tep over" } )
    vim.keymap.set( "n", "<Leader>di", dap.step_into, { desc = "Step [i]nto" } )
    vim.keymap.set( "n", "<Leader>do", dap.step_out, { desc = "Step [o]ut" } )
    vim.keymap.set( "n", "<Leader>dl", function() dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: ")) end, { desc = "Set breakpoint with [l]og message" } )
    vim.keymap.set( "n", "<Leader>dR", dap.repl.open, { desc = "Open [R]EPL" } )
    vim.keymap.set( "n", "<Leader>dr", dap.run_last, { desc = "[R]un last" } )

    vim.keymap.set( { "n", "v" }, "<Leader>dh", function()
      require("dap.ui.widgets").hover()
    end, { desc = "Open [h]over widget" } )

    vim.keymap.set( { "n", "v" }, "<Leader>dp", function()
      require("dap.ui.widgets").preview()
    end, { desc = "Open [p]review widget" } )

    vim.keymap.set( "n", "<Leader>df", function()
      local widgets = require("dap.ui.widgets")
      widgets.centered_float( widgets.frames )
    end, { desc = "Open [f]rames widget" } )

    vim.keymap.set( "n", "<Leader>dS", function()
      local widgets = require("dap.ui.widgets")
      widgets.centered_float( widgets.scopes )
    end, { desc = "Open [S]copes widget" } )

    -- Python: debugpy is installed by Mason (only when Python is present).
    if vim.fn.executable("debugpy-adapter") == 1 then
      require("dap-python").setup("debugpy-adapter")
    end
  end,
}
