#!/bin/bash
#
# install-shell-stack.sh
#
# Sets up a modern terminal stack on Debian/Ubuntu:
#   Shell      : zsh + zsh-autosuggestions + zsh-syntax-highlighting + starship prompt
#   Monitors   : btop
#   Multiplexer: tmux  (+ a starter ~/.tmux.conf)
#   Modern CLI : fzf, zoxide, eza, bat, ripgrep, fd
#   Aliases    : ~/.zsh_aliases swaps ls/cat/cd for the modern tools
#
# Safe to re-run: every step checks before acting and backs up files it replaces.
# Run as your normal user (NOT as root) — sudo is used only for apt:
#   ./install-shell-stack.sh

set -euo pipefail

### Colors (only if attached to a terminal) ###
if [ -t 1 ]; then
    RED=$(printf '\033[31m');    GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m'); BLUE=$(printf '\033[34m')
    BOLD=$(printf '\033[1m');    RESET=$(printf '\033[0m')
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; RESET=""
fi

info()  { echo "${BLUE}${BOLD}::${RESET} $*"; }
ok()    { echo "${GREEN}  ✓${RESET} $*"; }
warn()  { echo "${YELLOW}  !${RESET} $*"; }
die()   { echo "${RED}${BOLD}error:${RESET} $*" >&2; exit 1; }

### Sanity checks ###
[ "$(id -u)" -eq 0 ] && die "Don't run as root. Run as your user; sudo is used where needed."
command -v apt-get >/dev/null 2>&1 || die "apt-get not found — this script targets Debian/Ubuntu."
command -v sudo    >/dev/null 2>&1 || die "sudo not found — please install it first."

ZSH_CUSTOM="${HOME}/.zsh"
ZSHRC="${HOME}/.zshrc"
ALIASES="${HOME}/.zsh_aliases"
TMUXCONF="${HOME}/.tmux.conf"

backup_once() {  # backup_once <file> <marker> — back up only if not already managed by us
    local f="$1" marker="$2"
    if [ -f "$f" ] && ! grep -qF "$marker" "$f" 2>/dev/null; then
        local b="${f}.bak.$(date +%Y%m%d%H%M%S)"
        cp "$f" "$b"; ok "Backed up $(basename "$f") -> $b"
    fi
}

### 1. Base apt packages ###
info "Updating apt and installing base packages..."
sudo apt-get update -qq
sudo apt-get install -y zsh tmux git curl wget ca-certificates gpg
ok "Shell + tools installed"

info "Installing modern CLI tools from apt..."
# btop, fzf, ripgrep available on Debian 12 / Ubuntu 22.04+.
# bat -> binary 'batcat', fd-find -> binary 'fdfind' on Debian/Ubuntu.
# zoxide in Debian 12 / Ubuntu 21.04+.
for pkg in btop fzf ripgrep bat fd-find zoxide; do
    if sudo apt-get install -y "$pkg" 2>/dev/null; then
        ok "$pkg"
    else
        warn "$pkg not in this distro's apt repo — skipping (older OS?)."
    fi
done

### 2. eza (not in apt on most releases — add its official signed repo) ###
if command -v eza >/dev/null 2>&1; then
    ok "eza already installed"
elif sudo apt-get install -y eza 2>/dev/null; then
    ok "eza installed from apt"
else
    info "Adding eza's official apt repo..."
    sudo mkdir -p /etc/apt/keyrings
    if wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null; then
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
            | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt-get update -qq
        sudo apt-get install -y eza && ok "eza installed from official repo" \
            || warn "eza install failed — aliases will fall back to plain ls."
    else
        warn "Could not add eza repo — aliases will fall back to plain ls."
    fi
fi

### 3. Starship prompt (official installer — not packaged in apt) ###
if command -v starship >/dev/null 2>&1; then
    ok "starship already installed ($(starship --version | head -1))"
else
    info "Installing starship prompt..."
    curl -fsSL https://starship.rs/install.sh | sudo sh -s -- --yes
    ok "starship installed"
fi

### 4. Minimal zsh plugins (git clone — kept under ~/.zsh) ###
mkdir -p "$ZSH_CUSTOM"
clone_plugin() {
    local name="$1" url="$2" dest="${ZSH_CUSTOM}/$1"
    if [ -d "$dest/.git" ]; then
        info "Updating plugin $name..."
        git -C "$dest" pull --quiet --ff-only || warn "could not update $name"
    else
        info "Cloning plugin $name..."
        git clone --depth=1 --quiet "$url" "$dest"
    fi
    ok "$name ready"
}
clone_plugin zsh-autosuggestions     https://github.com/zsh-users/zsh-autosuggestions.git
clone_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git

### 5. Alias file — swap old commands for modern tools (guarded by availability) ###
backup_once "$ALIASES" "Managed by install-shell-stack.sh"
cat > "$ALIASES" <<'EOF'
# Managed by install-shell-stack.sh — modern CLI replacements.
# Aliases apply to interactive shells only, so scripts that call the real
# binaries (ls, cat, grep, find) are unaffected.

# ls -> eza (icons need a Nerd Font in your TERMINAL, not the server)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lh  --group-directories-first --git'
  alias la='eza -lah --group-directories-first --git'
  alias lt='eza --tree --level=2 --group-directories-first'
fi

# cat -> bat (auto-detects pipes and behaves like plain cat there)
if command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --paging=never'
  alias bat='batcat'
elif command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
fi

# fd is 'fdfind' on Debian/Ubuntu — expose the short name
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  alias fd='fdfind'
fi

# ripgrep (rg) and fd intentionally do NOT shadow grep/find — their syntax
# differs. Use 'rg pattern' and 'fd name' as the faster modern equivalents.
EOF
ok "Wrote $ALIASES"

### 6. .zshrc (managed block) ###
MARKER_START="# >>> install-shell-stack >>>"
MARKER_END="# <<< install-shell-stack <<<"
backup_once "$ZSHRC" "$MARKER_START"
# Strip any previous managed block so re-runs stay clean.
[ -f "$ZSHRC" ] && grep -qF "$MARKER_START" "$ZSHRC" \
    && sed -i "/${MARKER_START}/,/${MARKER_END}/d" "$ZSHRC"

cat >> "$ZSHRC" <<EOF
${MARKER_START}
# Managed by install-shell-stack.sh — edits inside this block are overwritten on re-run.

# History: large, shared, deduplicated.
HISTFILE="\$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE

# Completion.
autoload -Uz compinit && compinit -d "\$HOME/.zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive
bindkey -e   # emacs-style keybindings

# Aliases (modern CLI replacements).
[ -f "\$HOME/.zsh_aliases" ] && source "\$HOME/.zsh_aliases"

# Plugins (order matters: syntax-highlighting must be sourced last).
source "${ZSH_CUSTOM}/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "${ZSH_CUSTOM}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# fzf: fuzzy Ctrl-R history, Ctrl-T file picker, Alt-C cd-into-dir.
if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)                                   # fzf >= 0.48
  elif [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh   # older apt layout
    [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
  fi
fi

# zoxide: smarter cd. Replaces 'cd' so 'cd partial-name' jumps anywhere you've been.
command -v zoxide >/dev/null 2>&1 && eval "\$(zoxide init zsh --cmd cd)"

# Prompt (keep last).
eval "\$(starship init zsh)"
${MARKER_END}
EOF
ok "Updated $ZSHRC (managed block)"

### 7. tmux config ###
backup_once "$TMUXCONF" "Managed by install-shell-stack.sh"
cat > "$TMUXCONF" <<'EOF'
# Managed by install-shell-stack.sh — see tmux-instructions.md for the full guide.

# Prefix: Ctrl-a (closer to home row than the default Ctrl-b).
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Intuitive splits: | (vertical bar = vertical divider), - (horizontal divider).
# Both open in the current pane's directory.
unbind '"'; unbind %
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window     -c "#{pane_current_path}"

# Reload config: prefix + r
bind r source-file ~/.tmux.conf \; display "tmux.conf reloaded"

# Move between panes with Alt+arrows (no prefix needed).
bind -n M-Left  select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up    select-pane -U
bind -n M-Down  select-pane -D

# Quality of life.
set -g mouse on              # click/scroll/resize with the mouse
set -g base-index 1          # windows start at 1
setw -g pane-base-index 1    # panes start at 1
set -g renumber-windows on   # keep window numbers gapless after closing
set -g history-limit 100000  # bigger scrollback
set -sg escape-time 10       # snappier ESC (helps vim/zsh)
set -g status-style 'bg=default fg=cyan'   # subtle status bar
EOF
ok "Wrote $TMUXCONF"

### 8. Default shell ###
ZSH_BIN="$(command -v zsh)"
if [ "${SHELL:-}" = "$ZSH_BIN" ]; then
    ok "Default shell already zsh"
else
    info "Switching default login shell to zsh..."
    sudo chsh -s "$ZSH_BIN" "$USER" \
        && ok "Default shell set to $ZSH_BIN (effective next login)" \
        || warn "chsh failed — switch manually: chsh -s $ZSH_BIN"
fi

echo
echo "${GREEN}${BOLD}Done.${RESET} Start a new session, or run: ${BOLD}exec zsh${RESET}"
echo "tmux guide: ${BOLD}tmux-instructions.md${RESET}  |  monitor: ${BOLD}btop${RESET}"
echo "${YELLOW}Tip:${RESET} install a Nerd Font in your local terminal so prompt/eza icons render."
