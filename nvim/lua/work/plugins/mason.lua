-- Mason installs LSP servers/formatters into stdpath("data")/mason (user-writable, no admin).
-- Only an explicit list is installed; nothing is auto-installed on file open.
local has = function(exe)
  return vim.fn.executable(exe) == 1
end

local servers = { "lua_ls" } -- standalone binary, no runtime needed
local tools = { "stylua" }

if has("node") then -- npm-based packages need Node.js (install.sh puts a portable Node LTS in ~/.local/opt)
  vim.list_extend(servers, {
    "ts_ls",
    "html",
    "cssls",
    "jsonls",
    "tailwindcss",
    "svelte",
    "graphql",
    "emmet_ls",
    "prismals",
    "pyright",
    "bashls",
  })
  vim.list_extend(tools, { "prettier", "eslint_d" })
end

if has("python") or has("python3") then -- pip-based packages need Python with venv support
  vim.list_extend(tools, { "isort", "black", "pylint", "debugpy" })
end

return {
  "mason-org/mason.nvim", -- moved from williamboman/mason.nvim
  cmd = { "Mason", "MasonInstall", "MasonUpdate" },
  dependencies = {
    "mason-org/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  lazy = false,
  config = function()
    require("mason").setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    require("mason-lspconfig").setup({
      ensure_installed = {}, -- installs are handled by mason-tool-installer below
      automatic_enable = true, -- vim.lsp.enable() each installed server
    })

    -- One explicit list (lspconfig names are accepted because mason-lspconfig is installed).
    -- install.sh runs :MasonToolsInstallSync once; afterwards missing tools install on start.
    require("mason-tool-installer").setup({
      ensure_installed = vim.list_extend(vim.deepcopy(servers), tools),
      run_on_start = true,
    })
  end,
}
