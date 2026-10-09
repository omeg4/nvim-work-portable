# nvim-work-portable

[![Latest release](https://img.shields.io/github/v/release/omeg4/nvim-work-portable?sort=semver)](https://github.com/omeg4/nvim-work-portable/releases/latest)

A portable, safe-for-work Neovim + Git Bash setup for **Windows 11 + Windows Terminal + Git Bash**, installable by a **standard (non-admin) user** with one command.

It's derived from my personal Neovim config ("Neobruno"), with every plugin reviewed against three rules:

1. **No admin rights.** Everything installs into user-writable folders.
2. **No vulnerabilities or data capture.** No telemetry, no uploading of code or keystrokes, and every download pinned by version and SHA-256.
3. **LLM tools need an enterprise account.** Claude Code is only installed and enabled when it's locked to your company's organization. Copilot, Codeium and TabNine are removed.

The plugin-by-plugin review, including open risks, is in [REVIEW.md](REVIEW.md). It's also published as a formatted page: [Neobruno Plugin Audit](https://claude.ai/artifact/SS9Nbvaxezoe18c9cRMjpq).

## Install

### Requirements

- Windows 11 with [Git for Windows](https://git-scm.com/download/win) (provides Git Bash, `git`, `curl`, `sha256sum`). A per-user Git install works fine.
- [Windows Terminal](https://aka.ms/terminal) (preinstalled on Windows 11).
- A **normal, non-elevated** Git Bash window. The installer refuses to run as administrator.
- Network access to `github.com`, `objects.githubusercontent.com` and `nodejs.org`. If you use `--with-claude`, also `claude.ai` and `downloads.claude.ai`.

### Option 1: one-liner

In Git Bash:

```bash
curl -fsSL https://raw.githubusercontent.com/omeg4/nvim-work-portable/main/install.sh | bash
```

To pass options through the pipe, add `-s --` after `bash`:

```bash
curl -fsSL https://raw.githubusercontent.com/omeg4/nvim-work-portable/main/install.sh | bash -s -- --no-font
```

When piped, the script clones this repo to `~/.local/src/nvim-work-portable` (or updates an existing clone), then runs `install.sh` from there. The clone is your working copy for later edits.

This installs the latest version on `main`. To install a fixed version instead, see [Installing a specific version](#installing-a-specific-version).

### Option 2: clone and run

Use this if you'd rather read the script before running it:

```bash
git clone https://github.com/omeg4/nvim-work-portable.git ~/.local/src/nvim-work-portable
cd ~/.local/src/nvim-work-portable
less install.sh        # optional: read it first
./install.sh
```

### Installing a specific version

Releases are git tags such as `v1.0.1`. Each release's notes, including what changed and its known limitations, are on the [Releases page](https://github.com/omeg4/nvim-work-portable/releases); the newest is always at [releases/latest](https://github.com/omeg4/nvim-work-portable/releases/latest). You can also see the [tags page](https://github.com/omeg4/nvim-work-portable/tags), or run:

```bash
git ls-remote --tags https://github.com/omeg4/nvim-work-portable.git
```

To install a specific version with the one-liner, put the tag in **both** places:

```bash
curl -fsSL https://raw.githubusercontent.com/omeg4/nvim-work-portable/v1.0.1/install.sh | NVIM_WORK_REF=v1.0.1 bash
```

- **The tag in the URL** (`…/v1.0.1/install.sh`) picks which version of the bootstrap script you download and run.
- **`NVIM_WORK_REF=v1.0.1`** picks which version is cloned and installed. Without it, the bootstrap installs `main`, whichever URL you downloaded it from.
- **`NVIM_WORK_REF` goes right before `bash`, not before `curl`.** A variable set in front of a command applies only to that command, and it's `bash` that needs it. `NVIM_WORK_REF=v1.0.1 curl … | bash` silently installs `main`.

To pass installer options as well, add `-s --` and the options after `bash`:

```bash
curl -fsSL https://raw.githubusercontent.com/omeg4/nvim-work-portable/v1.0.1/install.sh | NVIM_WORK_REF=v1.0.1 bash -s -- --no-font
```

Things to know:

- **`NVIM_WORK_REF` takes a tag or a branch name**, not a commit hash. If the version doesn't exist (a typo, say), the installer stops with an error instead of installing something else.
- **The variable also switches an existing clone.** If `~/.local/src/nvim-work-portable` already exists, the bootstrap fetches, checks out the version you asked for and installs it. A tag checkout is a detached HEAD, which is expected.
- **Going back to the latest version:** run the plain one-liner again, without `NVIM_WORK_REF`. It switches the clone back to `main` and updates it.
- **Local edits are never overwritten.** If the checkout can't switch because of uncommitted changes in the clone, the installer prints a warning and installs the clone as it is.
- **Checking the installed version:** `git -C ~/.local/src/nvim-work-portable describe --tags`. The bootstrap also prints `Installing version: …` before it starts.

With the clone-and-run method, choose the version with git instead:

```bash
git clone --branch v1.0.1 https://github.com/omeg4/nvim-work-portable.git ~/.local/src/nvim-work-portable
# or, in an existing clone:
git -C ~/.local/src/nvim-work-portable fetch --tags --force && git -C ~/.local/src/nvim-work-portable checkout v1.0.1
~/.local/src/nvim-work-portable/install.sh
```

### After installing

1. Restart Windows Terminal so it picks up the new font and profile.
2. Open a tab with the **Git Bash (work)** profile. To make it the default: *Settings → Startup → Default profile*.
3. Run `nvim`, then `:checkhealth`.

The first install takes a few minutes. The installer downloads the tools, installs the plugins, compiles about 20 treesitter parsers and installs the language servers through Mason. Re-running it is safe: anything already installed at the pinned version is skipped.

## Installer options

| Option | Effect |
|---|---|
| `--with-claude --claude-org-uuid UUID` | Also install Claude Code, locked to your company's Claude for Teams/Enterprise organization. See [Claude Code](#claude-code-enterprise-only). |
| `--config-only` | Install only the Neovim config and `~/.bashrc`; download no tools. |
| `--no-node` | Skip Node.js. Mason then installs only `lua_ls` and `stylua` (plus Python tools, if Python is present). |
| `--no-toolchain` | Skip w64devkit (gcc/make). Treesitter parsers and telescope-fzf-native won't compile unless a C compiler is already on PATH. |
| `--no-font` | Skip the per-user CaskaydiaCove Nerd Font install. |
| `--no-terminal` | Skip the Windows Terminal profile. |
| `--appname NAME` | Install the config under `NVIM_APPNAME=NAME`. Default: `nvim` on Windows, `nvim-work` elsewhere. |
| `-h`, `--help` | Show help. |

Environment variables for the one-liner bootstrap:

| Variable | Default | Purpose |
|---|---|---|
| `NVIM_WORK_SRC` | `~/.local/src/nvim-work-portable` | Where the repo is cloned |
| `NVIM_WORK_REF` | `main` | Tag or branch to install, e.g. `v1.0.1`. See [Installing a specific version](#installing-a-specific-version). |
| `NVIM_WORK_REPO` | this repo's URL | Clone from a fork or a company mirror instead |

## What gets installed where

All paths are user-writable; nothing needs admin rights.

| What | Where |
|---|---|
| Neovim 0.12.6 | `~/.local/opt/nvim` |
| Node.js LTS, w64devkit (gcc + make) | `~/.local/opt/node`, `~/.local/opt/w64devkit` |
| ripgrep, fd, fzf, lazygit, tree-sitter CLI, `claude-work` | `~/.local/bin` |
| Neovim config | `%LOCALAPPDATA%\nvim` |
| Plugins, Mason packages, treesitter parsers | `%LOCALAPPDATA%\nvim-data` |
| CaskaydiaCove Nerd Font | `%LOCALAPPDATA%\Microsoft\Windows\Fonts`, plus a per-user registry entry |
| Windows Terminal profile and duskfox color scheme | `%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\WorkNvim` (your `settings.json` isn't edited) |
| Shell config | `~/.bashrc`, `~/.bash_profile` (made to source `~/.bashrc`), `~/.bashrc.local` |
| Download cache | `~/.cache/work-nvim-install` |

If a `~/.bashrc` or Neovim config already exists and differs, it's backed up with a `.bak.<timestamp>` suffix before being replaced.

Every tool download is pinned to a version and SHA-256 hash in the top section of `install.sh`. The installer stops if a hash doesn't match. Plugins are pinned to exact commits in `nvim/lazy-lock.json`.

## Claude Code (enterprise only)

Claude Code is **opt-in** and requires your company's Claude organization UUID. A claude.ai admin can find it under *Admin settings → Organization*.

```bash
./install.sh --with-claude --claude-org-uuid xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# or
curl -fsSL https://raw.githubusercontent.com/omeg4/nvim-work-portable/main/install.sh | bash -s -- --with-claude --claude-org-uuid xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

This does the following:

1. **Writes a Claude Code managed policy** to `HKCU\SOFTWARE\Policies\ClaudeCode`. The policy sets `forceLoginOrgUUID` to your organization, so Claude Code rejects logins to any other organization (personal Free/Pro/Max accounts) and blocks API-key credentials. It also turns telemetry, error reporting and feedback surveys off. If IT has already deployed a policy, the installer leaves it alone.
2. **Installs `claude-work`**, a guard that refuses to start Claude Code unless that policy is in effect. The `claude` command in `~/.bashrc` and the Neovim plugin (`<C-,>`) both go through it.
3. **Installs Claude Code** with Anthropic's official per-user installer, but only if step 1 succeeded.

If Windows won't let a standard user write that registry key, the installer installs nothing for Claude. It saves the policy JSON to `~/.cache/work-nvim-install/claude-managed-settings.json` so you can ask IT to deploy it.

Run `claude-work --status` to see which policy is in effect. The lock's known limits (for example, Claude Console logins aren't checked against the organization) are listed in [REVIEW.md](REVIEW.md#residual-gaps-and-uncertainties-claude-code).

## Using it

### Neovim highlights

The leader key is `Space`; press it and wait to see every mapping in which-key.

| Keys | Action |
|---|---|
| `<leader>ff` / `fs` / `fr` / `fc` | Find files / grep / recent files / word under cursor (Telescope) |
| `<leader>ee` | Toggle the file tree |
| `<leader>gg` | lazygit |
| `<leader>tt`, `<C-t>` | Toggle a terminal |
| `<leader>a` | Symbol outline (aerial) |
| `,f` `,w` `,t` | Hop motions |
| `gd` `gR` `K` `<leader>ca` `<leader>rn` | LSP: definition, references, hover, code action, rename |
| `<leader>mp` | Format file or selection (conform) |
| `<leader>v…` | Open this config's files |
| `<leader>pl` / `<leader>pm` | Lazy / Mason UI |
| `<C-,>` | Claude Code (only when the enterprise lock is in effect) |

### Shell shortcuts (`~/.bashrc`)

| Command | Does |
|---|---|
| `cdnv`, `cdnvp`, `cdnvd`, `cdlazy`, `cdmason`, `cdnvlog` | Go to the Neovim config, plugin specs, data folder, installed plugins, Mason packages, logs |
| `cdopt`, `cdclaude`, `cdwt`, `cdwtf`, `cdwork` | Go to the portable tools, `~/.claude`, Windows Terminal settings or fragments, your projects (`WORK_DIR`) |
| `nvc`, `nvk`, `bashrc`, `bashrcl`, `wtsettings` | Edit `init.lua`, `keymaps.lua`, `~/.bashrc`, `~/.bashrc.local`, Windows Terminal settings |
| `cdr`, `up N`, `mkcd DIR` | Go to the git root, go up N levels, make a folder and enter it |
| `bm NAME`, `j NAME`, `bml` | Bookmark the current folder, jump to a bookmark, list bookmarks |
| `fcd`, `fe`, `frg PATTERN`, `fnv` | Fuzzy: cd to a folder, open a file, grep and open at the matching line, open a config file |
| `nvim-health`, `nvim-update`, `nvim-restore` | Run `:checkhealth`; update plugins and parsers and show the lockfile diff; roll back to the lockfile |
| `open PATH`, `winpath`, `unixpath`, `pbcopy`, `pbpaste` | Windows helpers |

Put machine-specific settings in `~/.bashrc.local`, which the installer never overwrites. For example:

```bash
export WORK_DIR="$HOME/work"                 # used by `cdwork`
export WORK_NOTES_VAULT="$HOME/work/notes"   # enables obsidian.nvim for this vault
export HTTPS_PROXY=http://proxy.example.com:8080
```

## Updating and customizing

- **Update everything:** re-run the one-liner, or run `git pull && ./install.sh` in the clone. If you pinned a version, run the one-liner with a newer tag.
- **Change the config:** edit the files under `nvim/` in the clone, then run `./install.sh --config-only`. The installed config is replaced, and the old one is kept as `nvim.bak.<timestamp>`. If you edit `%LOCALAPPDATA%\nvim` directly instead, copy your changes back into the clone before re-running the installer.
- **Update plugins:** run `nvim-update`, review the lockfile diff, then copy `%LOCALAPPDATA%\nvim\lazy-lock.json` into the clone and commit it. Background update checks are off on purpose.
- **Bump a tool version:** in `install.sh`, update the version and its SHA-256 together. GitHub shows each release asset's digest; for Node.js, use `SHASUMS256.txt`.

## Uninstall

Delete these and restart Windows Terminal:

```bash
rm -rf ~/.local/opt/{nvim,node,w64devkit} ~/.cache/work-nvim-install ~/.local/src/nvim-work-portable
rm -f ~/.local/bin/{rg,fd,fzf,lazygit,tree-sitter}.exe ~/.local/bin/.*.version ~/.local/bin/claude-work
LAD="$(cygpath -u "$LOCALAPPDATA")"
rm -rf "$LAD/nvim" "$LAD/nvim-data" "$LAD/Microsoft/Windows Terminal/Fragments/WorkNvim"
# restore your previous shell config if a backup exists: ls ~/.bashrc.bak.*
# Claude Code lock (if installed): reg delete 'HKCU\SOFTWARE\Policies\ClaudeCode' //f
```

## Troubleshooting

| Symptom | Likely cause and fix |
|---|---|
| Downloaded `.exe` files won't run | Application control (AppLocker/WDAC) blocks executables in user folders. Ask IT; nothing in this setup can work around it. |
| `w64devkit self-extractor failed` | Usually the same policy. Re-run with `--no-toolchain`. |
| No syntax highlighting for some languages | Parsers failed to compile. Check `:checkhealth nvim-treesitter` and that `gcc` and `tree-sitter` are on PATH. |
| Downloads fail or hit TLS errors | Corporate proxy or TLS inspection. Set `HTTPS_PROXY`, and if needed `CURL_CA_BUNDLE` / `GIT_SSL_CAINFO`, in `~/.bashrc.local`. |
| Boxes instead of icons | The Nerd Font isn't selected or wasn't registered. Restart Windows Terminal; check the profile's font is *CaskaydiaCove Nerd Font*. |
| A plugin misbehaves running shell commands | Neovim uses Git Bash as its shell on Windows. `NVIM_KEEP_CMD=1 nvim` switches back to cmd.exe. |
| `claude-work: no managed policy…` | The enterprise lock isn't in effect. Run `claude-work --status`. |

## Other platforms

On Linux or macOS the installer copies the config and `~/.bashrc` but downloads no binaries; install Neovim ≥ 0.12, ripgrep, fd, lazygit and the tree-sitter CLI with your package manager. The config goes under `NVIM_APPNAME=nvim-work` so an existing `~/.config/nvim` is never overwritten.

## Repository layout

```
install.sh                 installer (also the curl | bash entry point)
bashrc                     installed as ~/.bashrc
nvim/                      Neovim config (installed to %LOCALAPPDATA%\nvim)
  init.lua
  lazy-lock.json           pinned plugin commits
  lua/work/core/           options, keymaps, Windows shell settings
  lua/work/plugins/        one file per plugin spec
claude/claude-work         enterprise-only guard for Claude Code
terminal/                  Windows Terminal profile fragment template
REVIEW.md                  plugin review against the three rules
```
