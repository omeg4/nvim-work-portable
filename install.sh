#!/usr/bin/env bash
# install.sh — portable, safe-for-work Terminal + Neovim setup.
#
# Target: Windows 11 + Windows Terminal + Git Bash, as a STANDARD (non-admin) user.
# Everything lands in user-writable locations:
#   ~/.local/opt/<tool>              Neovim, Node.js, w64devkit (gcc/make)
#   ~/.local/bin                     rg, fd, fzf, lazygit, tree-sitter, claude-work
#   %LOCALAPPDATA%\nvim              Neovim config (this repo's nvim/ directory)
#   %LOCALAPPDATA%\nvim-data         plugins (lazy), Mason packages, treesitter parsers
#   %LOCALAPPDATA%\Microsoft\Windows\Fonts      Nerd Font (per-user font install)
#   %LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\WorkNvim   Windows Terminal profile
#   ~/.bashrc, ~/.bash_profile, ~/.bashrc.local
#
# Every download is pinned to a version AND a SHA-256 digest; a mismatch aborts the install.
#
# Usage: ./install.sh [options]
#    or: curl -fsSL https://raw.githubusercontent.com/omeg4/nvim-work-portable/main/install.sh | bash
#        (append `-s -- [options]` after `bash` to pass options through the pipe)
#   When piped, the script first clones the repo to ~/.local/src/nvim-work-portable (or updates
#   an existing clone) and re-runs the install.sh from that clone. Override with NVIM_WORK_SRC,
#   NVIM_WORK_REPO, NVIM_WORK_REF (branch or tag to install, e.g. NVIM_WORK_REF=v1.0.0).
#
#   --with-claude --claude-org-uuid UUID
#                     Also set up Claude Code, locked to your company's Claude for Teams/Enterprise
#                     organization (Admin settings > Organization on claude.ai shows the UUID).
#                     Without a valid org lock, Claude Code is NOT installed.
#   --config-only     Only install the Neovim config + bashrc (skip all binary downloads)
#   --no-node         Skip Node.js (Mason then installs only lua_ls + stylua [+ Python tools])
#   --no-toolchain    Skip w64devkit (gcc/make). Treesitter parsers and fzf-native won't build
#                     unless you already have a C compiler on PATH.
#   --no-font         Skip the per-user Nerd Font install
#   --no-terminal     Skip the Windows Terminal profile fragment
#   --appname NAME    Install the config as NVIM_APPNAME=NAME (default: nvim on Windows,
#                     nvim-work elsewhere so a personal ~/.config/nvim is never overwritten)
#   -h, --help
set -euo pipefail

# The whole script is one { ... } block so bash reads all of it before running anything.
# That matters for `curl | bash`: a truncated download can't run half a script, and commands
# that read stdin can't swallow the rest of the script from the pipe.
{

# ─── Remote bootstrap (curl | bash) ──────────────────────────────────────────
# Piped input has no script file next to an nvim/ directory: clone the repo, then re-run from it.
_self="${BASH_SOURCE[0]:-}"
if [[ -z $_self || ! -f $_self || ! -d "$(dirname "$_self")/nvim" ]]; then
  repo_url="${NVIM_WORK_REPO:-https://github.com/omeg4/nvim-work-portable.git}"
  repo_ref="${NVIM_WORK_REF:-main}"
  src_dir="${NVIM_WORK_SRC:-$HOME/.local/src/nvim-work-portable}"
  command -v git >/dev/null || { echo "ERROR: git is required (install Git for Windows)" >&2; exit 1; }
  if [[ -d $src_dir/.git ]]; then
    echo "==> Updating existing checkout: $src_dir"
  elif [[ -e $src_dir ]]; then
    echo "ERROR: $src_dir exists but is not a git checkout; move it or set NVIM_WORK_SRC" >&2
    exit 1
  else
    echo "==> Cloning $repo_url -> $src_dir"
    mkdir -p "$(dirname "$src_dir")"
    git clone --quiet "$repo_url" "$src_dir"
  fi
  # Switch to the requested tag or branch. A tag leaves a detached HEAD; a branch is
  # fast-forwarded. A ref that doesn't exist is an error (a typo must not install something else).
  git -C "$src_dir" fetch --quiet --tags origin
  if git -C "$src_dir" rev-parse -q --verify "refs/tags/$repo_ref" >/dev/null; then
    target="refs/tags/$repo_ref"
  elif git -C "$src_dir" rev-parse -q --verify "refs/remotes/origin/$repo_ref" >/dev/null; then
    target="$repo_ref"
  else
    echo "ERROR: version '$repo_ref' not found in $repo_url" >&2
    echo "       list versions with: git ls-remote --tags $repo_url" >&2
    exit 1
  fi
  if git -C "$src_dir" checkout --quiet "$target" 2>/dev/null; then
    if git -C "$src_dir" symbolic-ref -q HEAD >/dev/null; then
      git -C "$src_dir" merge --ff-only --quiet "origin/$repo_ref" ||
        echo "  ! could not fast-forward $repo_ref (local commits?); installing the checkout as-is" >&2
    fi
  else
    echo "  ! could not switch to '$repo_ref' (local changes in $src_dir); installing the checkout as-is" >&2
  fi
  echo "==> Installing version: $(git -C "$src_dir" describe --tags --always 2>/dev/null)"
  # Give the real installer the terminal as stdin (the pipe is spent) when one is available.
  if { : </dev/tty; } 2>/dev/null; then
    exec bash "$src_dir/install.sh" "$@" </dev/tty
  fi
  exec bash "$src_dir/install.sh" "$@"
fi
unset _self

# ─── Pinned versions + SHA-256 (GitHub release asset digests / nodejs.org SHASUMS256.txt) ──────
# Bump deliberately: update version + hash together after checking the release notes.
NVIM_VER=v0.12.6
NVIM_SHA=4e12b7103b601ffc8f25954b4da100f339faa73dccb69a5b135e897fa3d893ed
TS_VER=v0.27.1
TS_SHA=de043e4c289efcef7981df99988300f23763befdeb36abf7c1898f080c478424
RG_VER=15.2.0
RG_SHA=71b2fef860abe467217a538ff31de02f5258807c0129f771846f87bd029aafc5
FD_VER=v10.5.0
FD_SHA=a227701b8551c35a9931d9f6da75503cf86d88e182d71fb849a70864c5d57cd7
LAZYGIT_VER=0.66.0
LAZYGIT_SHA=ed8fab4af7b8bac474084e976214a96569dea841c9f9b293502b83d8c3163e4b
FZF_VER=0.74.4
FZF_SHA=5e63c0e798406fcb9c51a9fed4988398e25fdabf8c670e32c16caf7b4a7ed02d
NODE_VER=v24.21.0 # LTS "Krypton"
NODE_SHA=158f7685b44de51f6c0df1d153526cbcd3e1bc739a8dfc607721cef75de9e541
W64DK_VER=2.10.0
W64DK_SHA=18d0a4c71a166f8401ab6305781bec5882b40b5e06ba9807c61cb5f3b3c6325e
NERDFONT_VER=v3.5.1
NERDFONT_SHA=1298bf92698afa06185cf1d05e6ae05f2d8a1e8c3cb45ddf4c3035168ab342a1

# ─── Options ─────────────────────────────────────────────────────────────────
WITH_CLAUDE=0
CLAUDE_ORG_UUID=""
CONFIG_ONLY=0
WITH_NODE=1
WITH_TOOLCHAIN=1
WITH_FONT=1
WITH_TERMINAL=1
APPNAME=""

usage() { sed -n '2,/^set -euo/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit "${1:-0}"; }

while (($#)); do
  case "$1" in
    --with-claude) WITH_CLAUDE=1 ;;
    --claude-org-uuid) CLAUDE_ORG_UUID="${2:-}"; shift ;;
    --config-only) CONFIG_ONLY=1 ;;
    --no-node) WITH_NODE=0 ;;
    --no-toolchain) WITH_TOOLCHAIN=0 ;;
    --no-font) WITH_FONT=0 ;;
    --no-terminal) WITH_TERMINAL=0 ;;
    --appname) APPNAME="${2:-}"; shift ;;
    -h | --help) usage 0 ;;
    *) echo "unknown option: $1" >&2; usage 1 ;;
  esac
  shift
done

# ─── Helpers ─────────────────────────────────────────────────────────────────
c_info=$'\e[36m' c_ok=$'\e[32m' c_warn=$'\e[33m' c_err=$'\e[31m' c_off=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$c_info" "$*" "$c_off"; }
ok() { printf '  %s✓%s %s\n' "$c_ok" "$c_off" "$*"; }
warn() { printf '  %s!%s %s\n' "$c_warn" "$c_off" "$*"; WARNINGS+=("$*"); }
die() { printf '%sERROR:%s %s\n' "$c_err" "$c_off" "$*" >&2; exit 1; }
WARNINGS=()

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="$HOME/.local"
OPT="$PREFIX/opt"
BIN="$PREFIX/bin"
CACHE="$HOME/.cache/work-nvim-install"
STAMP=$(date +%Y%m%d-%H%M%S)

case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*) IS_WINDOWS=1 ;;
  *) IS_WINDOWS=0 ;;
esac

if [[ -z $APPNAME ]]; then
  if [[ $IS_WINDOWS == 1 ]]; then APPNAME=nvim; else APPNAME=nvim-work; fi
fi

if [[ $IS_WINDOWS == 1 ]]; then
  LAD="$(cygpath -u "${LOCALAPPDATA:-$USERPROFILE/AppData/Local}")"
  NVIM_CFG="$LAD/$APPNAME"
  NVIM_DATA="$LAD/$APPNAME-data"
else
  NVIM_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/$APPNAME"
  NVIM_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/$APPNAME"
fi

# Run a Windows-native command without Git Bash rewriting /switch arguments into paths.
win() { MSYS2_ARG_CONV_EXCL='*' "$@"; }
pwsh_run() { powershell.exe -NoProfile -NonInteractive -Command "$@"; }

need() { command -v "$1" >/dev/null || die "required command not found: $1"; }

# download URL SHA256 -> prints cached file path; aborts on checksum mismatch
fetch() {
  local url="$1" sha="$2" out
  out="$CACHE/$(basename "$url")"
  if [[ ! -f $out ]] || ! echo "$sha  $out" | sha256sum -c --status; then
    echo "  downloading $(basename "$url")" >&2
    curl -fL --retry 3 --proto '=https' --tlsv1.2 -o "$out.part" "$url" || die "download failed: $url"
    mv "$out.part" "$out"
  fi
  echo "$sha  $out" | sha256sum -c --status || {
    rm -f "$out"
    die "SHA-256 mismatch for $(basename "$url") — refusing to install it."
  }
  echo "$out"
}

# extract ZIP DESTDIR (Git Bash lacks unzip on some installs; Windows ships bsdtar as tar.exe)
unzip_to() {
  local zip="$1" dest="$2"
  mkdir -p "$dest"
  if command -v unzip >/dev/null; then
    unzip -q -o "$zip" -d "$dest"
  elif [[ -x /c/Windows/System32/tar.exe ]]; then
    /c/Windows/System32/tar.exe -xf "$(cygpath -w "$zip")" -C "$(cygpath -w "$dest")"
  elif [[ $IS_WINDOWS == 1 ]]; then
    pwsh_run "Expand-Archive -Force -LiteralPath '$(cygpath -w "$zip")' -DestinationPath '$(cygpath -w "$dest")'"
  else
    die "no unzip tool available"
  fi
}

installed_ver() { cat "$1/.work-nvim-version" 2>/dev/null || true; }
mark_ver() { echo "$2" >"$1/.work-nvim-version"; }

# install a single .exe out of a zip into ~/.local/bin
install_exe_from_zip() {
  local name="$1" ver="$2" url="$3" sha="$4" exe="$5"
  if [[ -x "$BIN/$exe" && "$(cat "$BIN/.$exe.version" 2>/dev/null)" == "$ver" ]]; then
    ok "$name $ver already installed"
    return
  fi
  local zip tmp found
  zip="$(fetch "$url" "$sha")"
  tmp="$(mktemp -d)"
  unzip_to "$zip" "$tmp"
  found="$(find "$tmp" -type f -name "$exe" | head -1)"
  [[ -n $found ]] || die "$exe not found inside $(basename "$zip")"
  cp -f "$found" "$BIN/$exe"
  chmod +x "$BIN/$exe"
  echo "$ver" >"$BIN/.$exe.version"
  rm -rf "$tmp"
  ok "$name $ver -> ~/.local/bin/$exe"
}

# install a zip whose single top-level directory becomes ~/.local/opt/NAME
install_dir_from_zip() {
  local name="$1" ver="$2" url="$3" sha="$4"
  if [[ "$(installed_ver "$OPT/$name")" == "$ver" ]]; then
    ok "$name $ver already installed"
    return
  fi
  local zip tmp top
  zip="$(fetch "$url" "$sha")"
  tmp="$(mktemp -d)"
  unzip_to "$zip" "$tmp"
  top="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -1)"
  [[ -n $top ]] || die "unexpected layout in $(basename "$zip")"
  rm -rf "$OPT/$name.old"
  [[ -d "$OPT/$name" ]] && mv "$OPT/$name" "$OPT/$name.old"
  mv "$top" "$OPT/$name"
  rm -rf "$OPT/$name.old" "$tmp"
  mark_ver "$OPT/$name" "$ver"
  ok "$name $ver -> ~/.local/opt/$name"
}

# copy SRC over DEST, keeping a timestamped backup of whatever was there
install_file() {
  local src="$1" dest="$2"
  if [[ -e $dest ]] && ! cmp -s "$src" "$dest"; then
    cp -a "$dest" "$dest.bak.$STAMP"
    ok "backed up existing $(basename "$dest") -> $(basename "$dest").bak.$STAMP"
  fi
  mkdir -p "$(dirname "$dest")"
  cp -f "$src" "$dest"
}

# ─── 0. Preflight ────────────────────────────────────────────────────────────
step "Preflight"
need git
need curl
need sha256sum
mkdir -p "$OPT" "$BIN" "$CACHE"

if [[ $IS_WINDOWS == 1 ]]; then
  # `net session` only succeeds in an elevated shell. This setup must run as the normal user,
  # otherwise files end up owned by the admin account (and it would violate the no-admin rule).
  if net session >/dev/null 2>&1; then
    die "this shell is elevated (Run as administrator). Re-run install.sh from a normal Git Bash."
  fi
  ok "running as a standard user"
else
  [[ $EUID -ne 0 ]] || die "do not run as root"
  if [[ $CONFIG_ONLY == 0 ]]; then
    warn "not on Windows: skipping binary downloads (use your package manager for nvim>=0.12, rg, fd, lazygit, tree-sitter)"
    CONFIG_ONLY=1
  fi
fi

if [[ $WITH_CLAUDE == 1 ]]; then
  [[ $CLAUDE_ORG_UUID =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]] ||
    die "--with-claude requires --claude-org-uuid <your company's Claude organization UUID>"
  [[ $IS_WINDOWS == 1 ]] || die "--with-claude is only automated on Windows (managed settings elsewhere need root)"
fi

# ─── 1. Tools (pinned + verified) ────────────────────────────────────────────
if [[ $CONFIG_ONLY == 0 ]]; then
  step "Neovim $NVIM_VER"
  install_dir_from_zip nvim "$NVIM_VER" \
    "https://github.com/neovim/neovim/releases/download/$NVIM_VER/nvim-win64.zip" "$NVIM_SHA"

  step "CLI tools"
  install_exe_from_zip ripgrep "$RG_VER" \
    "https://github.com/BurntSushi/ripgrep/releases/download/$RG_VER/ripgrep-$RG_VER-x86_64-pc-windows-msvc.zip" "$RG_SHA" rg.exe
  install_exe_from_zip fd "$FD_VER" \
    "https://github.com/sharkdp/fd/releases/download/$FD_VER/fd-$FD_VER-x86_64-pc-windows-msvc.zip" "$FD_SHA" fd.exe
  install_exe_from_zip lazygit "$LAZYGIT_VER" \
    "https://github.com/jesseduffield/lazygit/releases/download/v$LAZYGIT_VER/lazygit_${LAZYGIT_VER}_windows_x86_64.zip" "$LAZYGIT_SHA" lazygit.exe
  install_exe_from_zip fzf "$FZF_VER" \
    "https://github.com/junegunn/fzf/releases/download/v$FZF_VER/fzf-$FZF_VER-windows_amd64.zip" "$FZF_SHA" fzf.exe
  install_exe_from_zip tree-sitter "$TS_VER" \
    "https://github.com/tree-sitter/tree-sitter/releases/download/$TS_VER/tree-sitter-cli-windows-x64.zip" "$TS_SHA" tree-sitter.exe

  if [[ $WITH_NODE == 1 ]]; then
    step "Node.js $NODE_VER (for Mason's npm-based language servers)"
    install_dir_from_zip node "$NODE_VER" \
      "https://nodejs.org/dist/$NODE_VER/node-$NODE_VER-win-x64.zip" "$NODE_SHA"
  fi

  if [[ $WITH_TOOLCHAIN == 1 ]]; then
    step "w64devkit $W64DK_VER (gcc + make, for treesitter parsers and telescope-fzf-native)"
    if [[ "$(installed_ver "$OPT/w64devkit")" == "$W64DK_VER" ]]; then
      ok "w64devkit $W64DK_VER already installed"
    else
      sfx="$(fetch "https://github.com/skeeto/w64devkit/releases/download/v$W64DK_VER/w64devkit-x64-$W64DK_VER.7z.exe" "$W64DK_SHA")"
      rm -rf "$OPT/w64devkit"
      # 7-Zip self-extractor: -o<dir> output directory, -y assume yes. Creates <dir>/w64devkit.
      win "$sfx" -y -o"$(cygpath -w "$OPT")" >/dev/null ||
        die "w64devkit self-extractor failed (an application-control policy may block it; use --no-toolchain)"
      [[ -x "$OPT/w64devkit/bin/gcc.exe" ]] || die "w64devkit extracted to an unexpected location"
      mark_ver "$OPT/w64devkit" "$W64DK_VER"
      ok "w64devkit $W64DK_VER -> ~/.local/opt/w64devkit"
    fi
  fi

  if [[ $WITH_FONT == 1 ]]; then
    step "Nerd Font (CaskaydiaCove, per-user install)"
    fontdir="$LAD/Microsoft/Windows/Fonts"
    if compgen -G "$fontdir/CaskaydiaCoveNerdFont-Regular.ttf" >/dev/null; then
      ok "CaskaydiaCove Nerd Font already installed"
    else
      zip="$(fetch "https://github.com/ryanoasis/nerd-fonts/releases/download/$NERDFONT_VER/CascadiaCode.zip" "$NERDFONT_SHA")"
      tmp="$(mktemp -d)"
      unzip_to "$zip" "$tmp"
      mkdir -p "$fontdir"
      n=0
      for f in "$tmp"/CaskaydiaCoveNerdFont-*.ttf; do
        cp -f "$f" "$fontdir/"
        face="$(basename "$f" .ttf | sed 's/CaskaydiaCoveNerdFont-/CaskaydiaCove Nerd Font /')"
        # Per-user font registration (Windows 10 1809+). No admin needed.
        win reg.exe add 'HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts' \
          /v "$face (TrueType)" /t REG_SZ /d "$(cygpath -w "$fontdir/$(basename "$f")")" /f >/dev/null ||
          warn "could not register font $face (policy may block per-user fonts)"
        n=$((n + 1))
      done
      rm -rf "$tmp"
      ok "installed $n font files (restart Windows Terminal to pick them up)"
    fi
  fi
fi

# ─── 2. Neovim config ────────────────────────────────────────────────────────
step "Neovim config -> $NVIM_CFG"
if [[ -d $NVIM_CFG ]]; then
  if diff -rq "$REPO_DIR/nvim" "$NVIM_CFG" -x lazy-lock.json >/dev/null 2>&1; then
    ok "config already up to date"
  else
    mv "$NVIM_CFG" "$NVIM_CFG.bak.$STAMP"
    ok "backed up existing config -> $(basename "$NVIM_CFG").bak.$STAMP"
  fi
fi
if [[ ! -d $NVIM_CFG ]]; then
  mkdir -p "$(dirname "$NVIM_CFG")"
  cp -r "$REPO_DIR/nvim" "$NVIM_CFG"
  ok "copied config"
fi

# ─── 3. Shell ────────────────────────────────────────────────────────────────
step "Shell: ~/.bashrc"
install_file "$REPO_DIR/bashrc" "$HOME/.bashrc"
ok "installed ~/.bashrc"
if [[ ! -f $HOME/.bashrc.local ]]; then
  cat >"$HOME/.bashrc.local" <<'EOF'
# ~/.bashrc.local — machine-specific settings (not managed by install.sh)
# export WORK_DIR="$HOME/work"                 # used by `cdwork`
# export WORK_NOTES_VAULT="$HOME/work/notes"   # enables obsidian.nvim for this vault
# export HTTPS_PROXY=http://proxy.example.com:8080
EOF
  ok "created ~/.bashrc.local template"
fi
# Git Bash starts login shells, which read ~/.bash_profile (not ~/.bashrc).
if ! grep -qs 'bashrc' "$HOME/.bash_profile"; then
  printf '\n# Load interactive settings\n[ -f ~/.bashrc ] && . ~/.bashrc\n' >>"$HOME/.bash_profile"
  ok "~/.bash_profile now sources ~/.bashrc"
fi
if [[ $APPNAME != nvim ]]; then
  grep -qs "NVIM_APPNAME=$APPNAME" "$HOME/.bashrc.local" ||
    echo "export NVIM_APPNAME=$APPNAME" >>"$HOME/.bashrc.local"
  ok "NVIM_APPNAME=$APPNAME exported from ~/.bashrc.local"
fi

# ─── 4. Windows Terminal profile (fragment: no edits to settings.json) ──────
if [[ $IS_WINDOWS == 1 && $WITH_TERMINAL == 1 ]]; then
  step "Windows Terminal profile"
  git_root="$(cygpath -w / | sed 's/\\$//')"
  bash_exe="$git_root\\bin\\bash.exe"
  [[ -f "$(cygpath -u "$bash_exe")" ]] || bash_exe="$(cygpath -w "$(type -P bash)")"
  icon="$git_root\\mingw64\\share\\git\\git-for-windows.ico"
  frag_dir="$LAD/Microsoft/Windows Terminal/Fragments/WorkNvim"
  mkdir -p "$frag_dir"
  jesc() { sed 's/\\/\\\\/g' <<<"$1"; }
  sed -e "s|@BASH@|$(jesc "$bash_exe")|" -e "s|@ICON@|$(jesc "$icon")|" \
    "$REPO_DIR/terminal/work-nvim.json.in" >"$frag_dir/work-nvim.json"
  ok "added profile 'Git Bash (work)' with duskfox colors"
  ok "set it as default: Windows Terminal > Settings > Startup > Default profile"
fi

# ─── 5. Claude Code (opt-in, enterprise-locked) ──────────────────────────────
install_file "$REPO_DIR/claude/claude-work" "$BIN/claude-work"
chmod +x "$BIN/claude-work"

if [[ $WITH_CLAUDE == 1 ]]; then
  step "Claude Code (locked to org $CLAUDE_ORG_UUID)"
  policy_tmp="$(mktemp --suffix=.json)"
  cat >"$policy_tmp" <<EOF
{
  "forceLoginMethod": "claudeai",
  "forceLoginOrgUUID": ["$CLAUDE_ORG_UUID"],
  "allowedProviders": ["anthropic"],
  "env": {
    "DISABLE_TELEMETRY": "1",
    "DISABLE_ERROR_REPORTING": "1",
    "CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY": "1",
    "DISABLE_FEEDBACK_COMMAND": "1"
  }
}
EOF
  # If IT already deployed an admin policy (HKLM / Program Files), it takes precedence and the
  # HKCU value would be ignored — so only write HKCU when no admin policy exists.
  admin_policy=0
  win reg.exe query 'HKLM\SOFTWARE\Policies\ClaudeCode' /v Settings >/dev/null 2>&1 && admin_policy=1
  [[ -f "$(cygpath -u "${ProgramW6432:-C:\\Program Files}")/ClaudeCode/managed-settings.json" ]] && admin_policy=1

  if [[ $admin_policy == 1 ]]; then
    ok "an admin-deployed Claude Code policy exists; leaving it in charge"
  else
    # PowerShell reads the JSON from a file, so no quoting of JSON through cmd/reg.exe is needed.
    if pwsh_run "\$ErrorActionPreference='Stop'; New-Item -Path 'HKCU:\SOFTWARE\Policies\ClaudeCode' -Force | Out-Null; Set-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\ClaudeCode' -Name Settings -Type String -Value (Get-Content -Raw -LiteralPath '$(cygpath -w "$policy_tmp")')" 2>/dev/null; then
      ok "wrote enterprise lock to HKCU\\SOFTWARE\\Policies\\ClaudeCode"
    else
      warn "could not write HKCU\\SOFTWARE\\Policies\\ClaudeCode (often locked down for standard users)."
      warn "Ask IT to deploy this as Claude Code managed settings: $(cygpath -w "$CACHE/claude-managed-settings.json")"
    fi
  fi
  cp "$policy_tmp" "$CACHE/claude-managed-settings.json"
  rm -f "$policy_tmp"

  if "$BIN/claude-work" --check; then
    ok "enterprise policy verified ($("$BIN/claude-work" --status | head -1))"
    if [[ -x "$BIN/claude.exe" ]]; then
      ok "Claude Code already installed (it self-updates)"
    else
      # Official native installer: installs to ~/.local/bin\claude.exe, no admin required.
      pwsh_run "irm https://claude.ai/install.ps1 | iex" || warn "Claude Code installer failed; see https://code.claude.com/docs/en/setup"
    fi
    # User-level defaults (the managed policy above is what actually enforces the lock).
    if [[ ! -f $HOME/.claude/settings.json ]]; then
      mkdir -p "$HOME/.claude"
      cat >"$HOME/.claude/settings.json" <<'EOF'
{
  "forceLoginMethod": "claudeai",
  "env": {
    "DISABLE_TELEMETRY": "1",
    "DISABLE_ERROR_REPORTING": "1",
    "CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY": "1"
  }
}
EOF
      ok "wrote ~/.claude/settings.json"
    else
      ok "kept existing ~/.claude/settings.json"
    fi
  else
    warn "enterprise policy NOT in effect: Claude Code was not installed and the Neovim plugin stays disabled."
  fi
fi

# ─── 6. Bootstrap Neovim (plugins, parsers, LSP servers) ─────────────────────
step "Bootstrapping Neovim plugins"
export PATH="$BIN:$OPT/nvim/bin:$OPT/node:$OPT/w64devkit/bin:$NVIM_DATA/mason/bin:$PATH"
export NVIM_APPNAME="$APPNAME"
[[ $IS_WINDOWS == 1 ]] && export CC="${CC:-gcc}"
command -v nvim >/dev/null || die "nvim not found on PATH"
nvim_ver="$(nvim --version | head -1)"
[[ $nvim_ver =~ v0\.1[2-9]|v[1-9] ]] || warn "$nvim_ver detected; this config targets Neovim >= 0.12"

nvim --headless "+Lazy! install" +qa 2>&1 | tail -n 3 || warn "lazy.nvim reported errors; run :Lazy in nvim"
ok "plugins installed at the commits pinned in lazy-lock.json"

if command -v tree-sitter >/dev/null && { command -v gcc >/dev/null || command -v cc >/dev/null || command -v cl >/dev/null; }; then
  step "Compiling treesitter parsers (a few minutes)"
  nvim --headless -c "lua require('nvim-treesitter').install(vim.g.work_ts_parsers):wait(900000)" -c qa 2>&1 |
    grep -Ei 'error|installed' | tail -n 30 || true
  n_parsers=$(find "$NVIM_DATA/site/parser" -type f 2>/dev/null | wc -l)
  if ((n_parsers > 0)); then ok "$n_parsers parsers built"; else warn "no parsers were built; run :checkhealth nvim-treesitter"; fi
else
  warn "tree-sitter CLI or C compiler missing: only Neovim's bundled parsers are available"
fi

step "Installing language servers & formatters with Mason"
nvim --headless "+MasonToolsInstallSync" +qa 2>&1 | grep -Ei 'error|fail' | tail -n 20 || true
ok "Mason done (inspect with :Mason)"

# ─── Summary ─────────────────────────────────────────────────────────────────
step "Done"
printf '  Neovim:   %s\n' "$(nvim --version | head -1)"
for t in rg fd fzf lazygit tree-sitter node gcc claude; do
  if command -v "$t" >/dev/null; then printf '  %-9s %s\n' "$t:" "$(command -v "$t")"; else printf '  %-9s %s\n' "$t:" "(not installed)"; fi
done
if ((${#WARNINGS[@]})); then
  printf '\n%sWarnings:%s\n' "$c_warn" "$c_off"
  printf '  - %s\n' "${WARNINGS[@]}"
fi
cat <<EOF

Next steps:
  1. Open a new Windows Terminal tab with the "Git Bash (work)" profile (or run: . ~/.bashrc)
  2. Run: nvim   then   :checkhealth
  3. Commit $NVIM_CFG/lazy-lock.json somewhere you control so future installs are reproducible.
EOF

exit 0
}
