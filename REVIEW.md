# Neobruno → work edition: plugin review & plan

Source: `~/.config/nvim` (personal). Target: Windows 11 + Windows Terminal + Git Bash, standard user.

Requirements checked for every plugin (including disabled ones and implicit dependencies):

- **R1 No admin.** The plugin, its install directory and any external tools it needs must work from user-writable locations.
- **R2 No vulnerabilities or data capture.** No telemetry, no uploading of keystrokes or code, no needless remote code execution.
- **R3 LLM = enterprise only.** Any LLM or MCP integration must *require* an enterprise account. Free or personal tiers must not work.

Verdicts: ✅ kept as-is · 🔧 kept with changes · ⛔ excluded (fails a requirement) · ➖ dropped (no requirement violated, but redundant, archived, or not applicable on Windows)

## Summary

| | Count |
|---|---|
| Plugins evaluated: 89 installed (incl. dependencies) + 9 disabled and never installed | 98 |
| Kept (✅/🔧), plus `lazydev.nvim` added as the neodev replacement | 68 |
| Excluded for R2/R3 (⛔) | 6 |
| Dropped for other reasons (➖) | 24 |

**No plugin in your config phones home or collects data on its own.** Every R2 or R3 problem comes from the external service or binary a plugin drives (Codeium, Copilot, TabNine, Claude Code), or from a build step that pulls a toolchain.

## 1. LLM / AI plugins (R3)

| Plugin | State in personal config | Verdict | Why |
|---|---|---|---|
| `greggh/claude-code.nvim` | enabled | 🔧 **kept, gated** | The plugin is just a terminal wrapper around the `claude` CLI (I read `terminal.lua`: it calls `termopen`, no network code). Claude Code itself accepts personal Pro/Max logins, so the plugin alone fails R3. It only passes because of the lock described below. |
| `Exafunction/codeium.nvim` (now `windsurf.nvim`) | disabled, **but also listed as an nvim-cmp dependency with `config = true`** | ⛔ excluded | Free individual tier is the default. It downloads a closed-source language-server binary that sends telemetry. An `enterprise_mode` (self-hosted `host`/`portal_url`) exists, but only helps if your employer runs Windsurf Enterprise. |
| `zbirenbaum/copilot.lua` | disabled | ⛔ excluded | Copilot Free and Individual are personal tiers, and a github.com login can't be restricted to an org seat on the client side. The one enforceable case is `auth_provider_url = "https://<corp>.ghe.com/"` (GitHub Enterprise Cloud with data residency), where personal accounts can't sign in. Re-add only if that applies to you. |
| `zbirenbaum/copilot-cmp` | **enabled (installed)**; its config calls `require('copilot').setup()` | ⛔ excluded | Same as copilot.lua. Note that in your personal config this was still active even though copilot.lua was disabled. |
| `ms-jpq/coq_nvim` | **enabled (installed)** | ⛔ excluded | Ships a TabNine client (`clients.tabnine`, off by default) that downloads the TabNine binary, an AI completion service with a free tier. It also needs a Python venv plus pip installs from PyPI (`:COQdeps`) and duplicates nvim-cmp (two completion engines were running). |

### How the Claude Code lock works (verified against code.claude.com docs, Oct 2026)

- Claude Code honours a managed policy `{"forceLoginMethod":"claudeai","forceLoginOrgUUID":["<org>"]}`. With it:
  - claude.ai logins to any other org (personal Free/Pro/Max) are rejected, and Claude Code exits at startup if the stored credential belongs to another org.
  - `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN` and `apiKeyHelper` are blocked at startup.
- **Normal location:** `HKLM\SOFTWARE\Policies\ClaudeCode` or `C:\Program Files\ClaudeCode\managed-settings.json`. Both need admin.
- **No-admin path:** Claude Code also reads `HKCU\SOFTWARE\Policies\ClaudeCode` (value `Settings`, REG_SZ) when no admin document exists. `install.sh --with-claude --claude-org-uuid <uuid>` writes the policy there and also sets `allowedProviders: ["anthropic"]` and telemetry off.
- `claude-work` is a guard wrapper. It refuses to start Claude Code unless the policy source Claude Code will actually apply pins `forceLoginOrgUUID`. The Neovim plugin (`cond`), the plugin's `command`, and the `claude` bash function all go through it.
- **No org UUID → no Claude Code.** The installer won't install it, and the Neovim plugin doesn't load.

### Residual gaps and uncertainties (Claude Code)

1. **Writing HKCU may be denied.** On many Windows builds, `HKCU\Software\Policies` is read-only for standard users, so writing there may fail even though Claude Code honours it. The installer detects the failure, does not install Claude Code, and saves the JSON for IT to deploy. **I can't test this from here.**
2. **It's self-imposed.** You can delete your own HKCU value. That's acceptable for "the config must not allow it", but it isn't tamper-proof. Only an IT-deployed HKLM/MDM policy is.
3. **Console logins aren't org-checked.** The docs say `forceLoginOrgUUID` only pre-selects the org for Claude *Console* logins, and the interactive login screen still lets someone choose Console even with `forceLoginMethod: "claudeai"`. A personal pay-as-you-go Console account could therefore get through. The guard can't detect this without parsing undocumented credential files. Mitigation: only use `/login` → claude.ai with your work SSO.
4. **`ant` CLI profiles aren't org-checked** (per the docs). The wrapper unsets `ANTHROPIC_PROFILE` and the federation variables, but a `default` profile written by `ant auth login` would still be read.
5. **Bedrock/Vertex/Foundry aren't supported.** If your company provides Claude through one of those instead of a Teams/Enterprise org, the wrapper needs a provider-specific mode (it currently unsets `CLAUDE_CODE_USE_*`) and `allowedProviders` needs changing.
6. The `irm https://claude.ai/install.ps1 | iex` installer isn't hash-pinned, because Anthropic doesn't publish a stable hash for the bootstrapper. Claude Code also auto-updates. Both are the vendor's signed distribution channel, but EDR tools sometimes flag the `irm | iex` pattern.

## 2. Excluded for R1/R2 (non-LLM)

| Plugin | Verdict | Why |
|---|---|---|
| `xvzc/chezmoi.nvim` | ⛔ | Built to sync dotfiles to a git remote, usually a personal GitHub. On a work laptop that's a data-leak path (work paths, hostnames, tokens in config). Also hard-codes `~/.local/share/chezmoi`. |
| `vhyrro/luarocks.nvim` | ⛔ | Bootstraps LuaRocks and builds Lua C modules: arbitrary packages from luarocks.org plus a C build chain at plugin-install time. Only needed by neorg (disabled). Unmaintained since 2024. |

## 3. Dropped (no violation, but redundant / archived / not applicable)

| Plugin | Why |
|---|---|
| `stevearc/dressing.nvim` | Archived upstream. `telescope-ui-select` already covers `vim.ui.select`. |
| `folke/lsp-colors.nvim` | Archived (2023). A no-op on modern Neovim. |
| `folke/neodev.nvim` | Archived. Replaced by `folke/lazydev.nvim`. |
| `ii14/emmylua-nvim` | nvim API type stubs. Superseded by lazydev. |
| `xubury/emmylua.nvim` | 0 stars, **no license**, npm build step (`npm install && npm run compile`). Unauditable supply chain. Its DAP config was also commented out. |
| `mxsdev/nvim-dap-vscode-js` | No commits since 2023, no license, needs a manual vscode-js-debug build. |
| `simrat39/symbols-outline.nvim` | Archived. `aerial.nvim` does the same job. |
| `nvimtools/none-ls.nvim` + `jay-babu/mason-null-ls.nvim` | `lazy = true` with no trigger, so they never loaded. conform.nvim covers formatting. (mason-null-ls is also AGPL-3.0, which some companies ban outright.) |
| `folke/neoconf.nvim` | Unused. Reads per-project `.neoconf.json`, i.e. settings injected by a cloned repo. |
| `LhKipp/nvim-nu` | Nushell support. Not applicable in Git Bash. |
| `christoomey/vim-tmux-navigator` | No tmux in Git Bash. Replaced with plain `<C-h/j/k/l>` window maps. |
| `baliestri/aura-theme` | Colorscheme from a non-default `feat/neovim-port` branch of a VS Code theme repo (20 stars, untouched since Jan 2025). Low trust for little value. |
| `navarasu/onedark.nvim`, `brunodark`, `olimorris/onedarkpro.nvim`, `bluz71/vim-nightfly-colors`, `tiagovla/tokyodark.nvim`, `rktjmp/lush.nvim` | Harmless, but several called `:colorscheme` in their own `config` and fought `init.lua` over the active theme. Kept nightfox (duskfox) plus catppuccin. Re-adding any of them is safe. |
| Disabled and unused: `nvim-neorg/neorg` (needs luarocks), `ggandor/leap.nvim` (moved to Codeberg), `nvim-neo-tree/neo-tree.nvim`, `akinsho/bufferline.nvim`, `yamatsum/nvim-nonicons` (needs an extra font), `vimwiki/vimwiki` | All compatible with R1–R3. Left out only because you had them disabled. |

## 4. Kept

✅ unchanged · 🔧 changed (reason given)

| Plugin(s) | | Notes |
|---|---|---|
| lazy.nvim | 🔧 | `checker` off (no background GitHub polling). `rocks.enabled = false`: your config nested it inside a positional table, so it was ignored. **lazy-lock.json is now committed** (your personal `.gitignore` excluded it). Pinned commits are the main supply-chain control. |
| plenary, which-key, nui, nvim-notify, noice, lualine, barbar, gitsigns, alpha-nvim, indent-blankline, todo-comments, trouble, diffview, nvim-tree, nvim-web-devicons, harpoon, hop, nvim-surround, vim-ReplaceWithRegister, Comment.nvim, nvim-autopairs, toggleterm, lspkind, friendly-snippets, cmp-* sources, nvim-cmp, nightfox, catppuccin | ✅ | Pure Lua/Vimscript, no network access. Comment.nvim now uses the ts-context-commentstring pre-hook. |
| telescope (+ fzf-native, ui-select) | 🔧 | fzf-native is C. It builds with `make` or `gcc` from w64devkit; without either it's skipped and telescope uses its Lua sorter. |
| LuaSnip | 🔧 | `make install_jsregexp` skipped on Windows (optional; only needed for regex snippet transforms). |
| nvim-treesitter + textobjects | 🔧 **branch change** | `master` officially supports Neovim 0.10–0.11 only, not 0.12. Moved to `main`: parsers compile via `tree-sitter build`, so the tree-sitter CLI plus a C compiler are installed in user space. `auto_install` removed (parsers are native DLLs built from third-party repos, so only the explicit list is installed). Textobjects keymaps ported to the new API. Swaps moved from `<leader>n*`/`<leader>p*`, which collided with noice and plugin management, to `<leader>xn*`/`<leader>xp*`. Your `,`/`<C-,>` repeat-move maps clobbered the Hop `,` group and the Claude `<C-,>` toggle, so they're removed. |
| nvim-ts-autotag, nvim-ts-context-commentstring | ✅ | |
| nvim-lspconfig, mason, mason-lspconfig, mason-tool-installer | 🔧 | Repos moved to `mason-org/`. Rewritten for `vim.lsp.config`/`vim.lsp.enable`. `automatic_installation` removed; one explicit list. npm-based servers only when Node exists, pip tools only when Python exists. `lua_ls` telemetry pinned **off**. Mason installs to `%LOCALAPPDATA%\nvim-data\mason`. |
| conform.nvim | 🔧 | Left the legacy `nvim-0.9` branch; `lsp_fallback` → `lsp_format`. |
| nvim-ufo, promise-async | 🔧 | Setup moved into the plugin spec (it used to run from core before ufo was guaranteed to load). |
| aerial.nvim | 🔧 | Your `opts` were indent-blankline v2 options, which aerial silently ignored. Replaced with a valid minimal config and `<leader>a`. |
| auto-session | 🔧 | Option names updated for v2 (`auto_restore`, `suppressed_dirs`). Session files stay local. |
| nvim-colorizer.lua, mini.nvim | 🔧 | Repos moved (`catgoose/`, `nvim-mini/`). |
| icon-picker.nvim | ✅ | Archived upstream, but pure Lua with no network access, pinned. |
| unicode.vim | ✅ | Downloads `UnicodeData.txt` from unicode.org on first use (download only). |
| vim-jsonviewer | ✅ ⚠ | 11 stars, no license. I read the source: pure Vimscript, no `system()`/job/network calls. Keep or drop as you like. |
| lazygit.nvim | ✅ | `lazygit.exe` is installed to `~/.local/bin`. |
| nvim-dap, nvim-dap-ui, nvim-nio, nvim-dap-python | 🔧 | Removed the Linux-only paths (`/usr/bin/wezterm`, `/usr/lib/node_modules/...`). debugpy comes from Mason (only if Python exists). Fixed duplicate `<leader>ds`/`<leader>dp` maps (now `dS`, `dR`). |
| vimtex (+ cmp-vimtex) | 🔧 | Loads only if `latexmk` is on PATH (MiKTeX supports a per-user install). Uses `latexmk` from PATH instead of `/usr/bin/latexmk`, and SumatraPDF if present. |
| obsidian.nvim | 🔧 | Loads only when `WORK_NOTES_VAULT` is set. `use_advanced_uri` off; `xdg-open` → `vim.ui.open`. **Don't point it at a personally-synced vault.** |
| render-markdown.nvim | ✅ | Still disabled, as in your config. Safe to enable. |
| claude-code.nvim | 🔧 | See §1. |

### Other fixes carried into the port

- `nvim_utils.lua` (≈650 lines of globals from norcalli/nvim_utils, unused) and `reload.lua` removed.
- `after/ftplugin/md.lua` never ran (`md` isn't a filetype) and would have errored (`vim.l`). Removed.
- Hardening: `modeline=false`, `exrc=false`, and `no_plugin_maps=1` (Python's ftplugin `]m` was shadowing the textobjects motion; found while testing).
- New quick-open maps for config files under `<leader>v` (from your README TODO).

## 5. External tools (R1): all in user space, pinned by version + SHA-256

| Tool | Version | Location | Why |
|---|---|---|---|
| Neovim | 0.12.6 | `~/.local/opt/nvim` | Bundles `win32yank.exe`, so the clipboard works |
| ripgrep / fd / fzf | 15.2.0 / 10.5.0 / 0.74.4 | `~/.local/bin` | telescope, todo-comments, bash helpers |
| lazygit | 0.66.0 | `~/.local/bin` | lazygit.nvim |
| tree-sitter CLI | 0.27.1 | `~/.local/bin` | nvim-treesitter `main` |
| w64devkit (gcc, make) | 2.10.0 | `~/.local/opt/w64devkit` | parser DLLs, fzf-native (`--no-toolchain` to skip) |
| Node.js LTS | 24.21.0 | `~/.local/opt/node` | Mason's npm servers (`--no-node` to skip) |
| CaskaydiaCove Nerd Font | 3.5.1 | per-user Fonts + HKCU registration | icons |
| Windows Terminal profile | — | JSON *fragment* under `%LOCALAPPDATA%` | no edits to your settings.json |

Hashes come from GitHub's per-asset `digest` field and nodejs.org's `SHASUMS256.txt`. The installer aborts on any mismatch and refuses to run elevated (`net session` check).

## 6. Uncertainties to check on the actual work laptop

1. **Application control (AppLocker/WDAC).** If IT blocks executables in user folders, none of this runs, including `nvim.exe`. The w64devkit self-extractor is the most likely thing to be blocked.
2. **gcc + `tree-sitter build` on Windows.** I verified the parser build end-to-end on Linux. On Windows, tree-sitter's compiler detection (the Rust `cc` crate, targeting MSVC) should accept `CC=gcc`, but I couldn't test it. If it fails, `:checkhealth nvim-treesitter` will say so. Neovim still highlights its bundled languages (c, lua, markdown, query, vim, vimdoc), and VS Build Tools (if IT provides them) would be the fallback compiler.
3. **Git Bash as Neovim's `shell`.** Set in `core/windows.lua` so `:!`, `:terminal` and the bash wrappers work. If a plugin misbehaves, `NVIM_KEEP_CMD=1 nvim` reverts to cmd.exe.
4. **Licenses.** Several kept plugins are GPL-3.0 (toggleterm, nvim-dap, dap-python), and a few have no license file (unicode.vim, vim-ReplaceWithRegister, vim-jsonviewer). Using them locally doesn't distribute anything, but some companies have blanket rules.
5. **Corporate proxy / TLS inspection.** curl, git and Mason may need `HTTPS_PROXY` or a corporate CA bundle. Put those in `~/.bashrc.local`.

## 7. What was tested here (Linux, Neovim 0.12.5)

- `install.sh` end to end with a throwaway `HOME`. The existing `.bashrc` was backed up; 68 plugins installed at the pinned commits; **22 parsers compiled via `tree-sitter build`**; all 19 Mason packages installed.
- Headless startup: no plugin errors; duskfox loaded; treesitter highlighting active; spot-checked keymaps (`,f`, `<leader>ff`, `<leader>xna`, `]m`); Claude plugin **not** loaded without a policy.
- `claude-work --check/--status` and the policy-detection regex.
- **Not tested:** anything Windows-specific (downloads, zip extraction, HKCU writes, fonts, Windows Terminal fragment, w64devkit).
