# ~/.bashrc — portable work shell (Git Bash on Windows 11; also fine on Linux/macOS bash)
# Installed by nvim-work-portable/install.sh. Put machine-specific settings in ~/.bashrc.local.

# Only for interactive shells
case $- in *i*) ;; *) return ;; esac

# ─── Platform ────────────────────────────────────────────────────────────────
case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*) IS_WINDOWS=1 ;;
  *) IS_WINDOWS=0 ;;
esac

if [[ $IS_WINDOWS == 1 ]]; then
  LOCALAPPDATA_U="$(cygpath -u "${LOCALAPPDATA:-$USERPROFILE/AppData/Local}")"
  NVIM_CONFIG_DIR="$LOCALAPPDATA_U/${NVIM_APPNAME:-nvim}"
  NVIM_DATA_DIR="$LOCALAPPDATA_U/${NVIM_APPNAME:-nvim}-data"
  NVIM_STATE_DIR="$NVIM_DATA_DIR"
  WT_SETTINGS_DIR="$LOCALAPPDATA_U/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState"
  WT_FRAGMENTS_DIR="$LOCALAPPDATA_U/Microsoft/Windows Terminal/Fragments"
else
  NVIM_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/${NVIM_APPNAME:-nvim}"
  NVIM_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/${NVIM_APPNAME:-nvim}"
  NVIM_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/${NVIM_APPNAME:-nvim}"
fi
export NVIM_CONFIG_DIR NVIM_DATA_DIR NVIM_STATE_DIR

# ─── PATH: user-space tools installed by install.sh (no admin) ──────────────
path_prepend() { [[ -d "$1" && ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"; }
path_prepend "$HOME/.local/opt/w64devkit/bin" # gcc + make for treesitter parsers / fzf-native
path_prepend "$HOME/.local/opt/node"          # Node.js LTS (Mason's npm-based LSP servers)
path_prepend "$NVIM_DATA_DIR/mason/bin"       # LSP servers / formatters installed by Mason
path_prepend "$HOME/.local/opt/nvim/bin"      # Neovim
path_prepend "$HOME/.local/bin"               # rg, fd, fzf, lazygit, tree-sitter, claude, claude-work
export PATH
unset -f path_prepend

# ─── Editor ──────────────────────────────────────────────────────────────────
export EDITOR=nvim VISUAL=nvim GIT_EDITOR=nvim
export MANPAGER='nvim +Man!'
[[ $IS_WINDOWS == 1 ]] && export CC="${CC:-gcc}" # compiler used by `tree-sitter build`

# ─── History & shell options ─────────────────────────────────────────────────
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE='ls:ll:la:cd:pwd:exit:clear:history'
shopt -s histappend cmdhist checkwinsize globstar cdspell dirspell autocd 2>/dev/null
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# ─── Prompt (git branch via Git for Windows' git-prompt.sh when available) ──
for _gp in /mingw64/share/git/completion/git-prompt.sh /usr/share/git/completion/git-prompt.sh \
  /usr/share/git-core/contrib/completion/git-prompt.sh /usr/lib/git-core/git-sh-prompt; do
  [[ -f $_gp ]] && { . "$_gp"; break; }
done
unset _gp
if declare -F __git_ps1 >/dev/null; then
  GIT_PS1_SHOWDIRTYSTATE=1 # set to empty if prompts feel slow in huge repos
  PS1='\[\e[36m\]\w\[\e[35m\]$(__git_ps1 " (%s)")\[\e[0m\]\n\$ '
else
  PS1='\[\e[36m\]\w\[\e[0m\]\n\$ '
fi

# ─── Navigation: config directories ──────────────────────────────────────────
alias cdnv='cd "$NVIM_CONFIG_DIR"'                         # nvim config
alias cdnvp='cd "$NVIM_CONFIG_DIR/lua/work/plugins"'       # plugin specs
alias cdnvd='cd "$NVIM_DATA_DIR"'                          # nvim data (plugins, mason, parsers)
alias cdlazy='cd "$NVIM_DATA_DIR/lazy"'                    # installed plugin sources
alias cdmason='cd "$NVIM_DATA_DIR/mason"'                  # Mason packages
alias cdnvlog='cd "$NVIM_STATE_DIR"'                       # logs (lsp.log etc.), sessions
alias cdopt='cd "$HOME/.local/opt"'                        # portable tools
alias cdclaude='cd "$HOME/.claude"'                        # Claude Code user settings
[[ $IS_WINDOWS == 1 ]] && alias cdwt='cd "$WT_SETTINGS_DIR"'      # Windows Terminal settings.json
[[ $IS_WINDOWS == 1 ]] && alias cdwtf='cd "$WT_FRAGMENTS_DIR"'    # Windows Terminal fragments
alias cdwork='cd "${WORK_DIR:-$HOME/work}"'                # your projects root (set WORK_DIR)

# Edit config files
alias nv='nvim'
alias nvc='nvim "$NVIM_CONFIG_DIR/init.lua" -c "cd $NVIM_CONFIG_DIR"'
alias nvk='nvim "$NVIM_CONFIG_DIR/lua/work/core/keymaps.lua"'
alias bashrc='nvim ~/.bashrc && . ~/.bashrc'
alias bashrcl='nvim ~/.bashrc.local && . ~/.bashrc'
alias reload='. ~/.bashrc && echo "~/.bashrc reloaded"'
[[ $IS_WINDOWS == 1 ]] && alias wtsettings='nvim "$WT_SETTINGS_DIR/settings.json"'

# Go to the root of the current git repo
cdr() { local r; r="$(git rev-parse --show-toplevel 2>/dev/null)" && cd "$r" || echo "not in a git repo"; }
# Go up N directories: `up 3`
up() { local n="${1:-1}" p=""; while ((n-- > 0)); do p="../$p"; done; cd "${p:-.}" || return; }
mkcd() { mkdir -p -- "$1" && cd -- "$1" || return; }

# Directory bookmarks persisted in ~/.bookmarks: `bm name` saves cwd, `j name` jumps, `bml` lists
bm() { [[ -n $1 ]] || { echo "usage: bm <name>"; return 1; }; sed -i "/^$1|/d" ~/.bookmarks 2>/dev/null; echo "$1|$PWD" >>~/.bookmarks; }
j() { local d; d="$(grep "^$1|" ~/.bookmarks 2>/dev/null | head -1 | cut -d'|' -f2-)"; [[ -n $d ]] && cd "$d" || echo "no bookmark '$1'"; }
bml() { column -t -s'|' ~/.bookmarks 2>/dev/null || echo "no bookmarks yet"; }
_j_complete() { COMPREPLY=($(compgen -W "$(cut -d'|' -f1 ~/.bookmarks 2>/dev/null)" -- "${COMP_WORDS[1]}")); }
complete -F _j_complete j

# ─── Fuzzy helpers (fzf + fd + rg, all user-space) ───────────────────────────
if command -v fzf >/dev/null; then
  command -v fd >/dev/null && export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
  eval "$(fzf --bash 2>/dev/null)" # Ctrl-T files, Ctrl-R history, Alt-C cd
  # fuzzy cd into a subdirectory
  fcd() { local d; d="$(fd --type d --hidden --exclude .git . "${1:-.}" | fzf)" && cd "$d" || return; }
  # fuzzy open a file in nvim
  fe() { local f; f="$(fzf --preview 'head -100 {}')" && nvim "$f"; }
  # ripgrep, pick a match, open nvim at that line
  frg() {
    local sel; sel="$(rg --line-number --no-heading --color=never "${@:-.}" | fzf --delimiter : --preview 'head -n +$(({2}+20)) {1} | tail -40')" || return
    nvim "$(cut -d: -f1 <<<"$sel")" +"$(cut -d: -f2 <<<"$sel")"
  }
  # jump to a nvim config file
  fnv() { local f; f="$(cd "$NVIM_CONFIG_DIR" && fd --type f . | fzf)" && nvim "$NVIM_CONFIG_DIR/$f"; }
fi

# ─── Listing & git shortcuts ─────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -alhF'
alias la='ls -A'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias g='git'
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias lg='lazygit'

# ─── Windows conveniences ────────────────────────────────────────────────────
if [[ $IS_WINDOWS == 1 ]]; then
  open() { explorer.exe "$(cygpath -w "${1:-.}")"; }   # open in Explorer / default app
  alias winpath='cygpath -w'                           # /c/foo -> C:\foo
  alias unixpath='cygpath -u'                          # C:\foo -> /c/foo
  alias pbcopy='clip.exe'
  alias pbpaste='powershell.exe -NoProfile -Command Get-Clipboard'
fi

# ─── Neovim maintenance ──────────────────────────────────────────────────────
nvim-health() { nvim -c 'checkhealth' ; }
# Update plugins deliberately, then review what changed in the lockfile before committing it.
nvim-update() {
  nvim --headless '+Lazy! sync' +qa &&
    nvim --headless -c "lua require('nvim-treesitter').update():wait(600000)" -c qa
  if git -C "$NVIM_CONFIG_DIR" rev-parse >/dev/null 2>&1; then
    git -C "$NVIM_CONFIG_DIR" --no-pager diff --stat -- lazy-lock.json
    echo "Review: git -C \"\$NVIM_CONFIG_DIR\" diff lazy-lock.json"
  fi
}
# Roll plugins back to the commits in lazy-lock.json
nvim-restore() { nvim --headless '+Lazy! restore' +qa; }

# ─── Claude Code: always route through the enterprise guard ──────────────────
# `claude` runs claude-work, which refuses to start unless a managed policy pins your
# company's org (forceLoginOrgUUID). Never export ANTHROPIC_API_KEY in this file.
if command -v claude-work >/dev/null; then
  claude() { claude-work "$@"; }
fi

# ─── Local overrides (not tracked): WORK_DIR, WORK_NOTES_VAULT, proxies, etc. ─
[[ -f ~/.bashrc.local ]] && . ~/.bashrc.local
