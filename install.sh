#!/usr/bin/env bash
#
# Mirror this machine's setup on a fresh macOS box with a single command.
# Idempotent: safe to re-run. Files that would be overwritten are backed up
# to ~/.dotfiles-backup/<timestamp>/ first.
#
# Usage: ./install.sh [options]
#   --dotfiles-only  Only copy shell/git dotfiles; skip brew, oh-my-zsh,
#                    editors, Warp, Claude, and the backup agent
#   --no-brew     Skip Homebrew install + `brew bundle`
#   --no-claude   Skip Claude Code config, skills, and plugins
#   --no-warp     Skip Warp terminal settings
#   --no-editors  Skip VS Code / Cursor settings
#   --with-agent  Install the daily launchd backup agent (no prompt)
#   --no-agent    Skip the daily-backup agent (no prompt)
#   -h, --help    Show this help

set -euo pipefail

DO_BREW=1 DO_CLAUDE=1 DO_WARP=1 DO_EDITORS=1 DO_OMZ=1 DOTFILES_ONLY=0 AGENT=ask
for arg in "$@"; do
  case "$arg" in
    --dotfiles-only) DOTFILES_ONLY=1 ;;
    --no-brew)    DO_BREW=0 ;;
    --no-claude)  DO_CLAUDE=0 ;;
    --no-warp)    DO_WARP=0 ;;
    --no-editors) DO_EDITORS=0 ;;
    --with-agent) AGENT=yes ;;
    --no-agent)   AGENT=no ;;
    -h|--help)
      sed -n '3,16p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown option: $arg (see --help)"; exit 1 ;;
  esac
done

# --dotfiles-only: copy shell/git files and nothing else.
if [ "$DOTFILES_ONLY" -eq 1 ]; then
  DO_BREW=0 DO_CLAUDE=0 DO_WARP=0 DO_EDITORS=0 DO_OMZ=0 AGENT=no
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  ! \033[0m%s\n' "$*"; }

# Copy a file into place, backing up any existing destination first.
install_file() {
  local src="$1" dest="$2"
  [ -f "$src" ] || { warn "missing source: $src"; return 0; }
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && ! diff -q "$src" "$dest" >/dev/null 2>&1; then
    mkdir -p "$BACKUP_DIR$(dirname "$dest")"
    cp "$dest" "$BACKUP_DIR$dest"
  fi
  cp "$src" "$dest"
}

# ---------------------------------------------------------------------------
# 1. Homebrew + packages (formulae, casks, cargo, npm, vscode extensions)
# ---------------------------------------------------------------------------
if [ "$DO_BREW" -eq 1 ]; then
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
  fi
  log "Installing packages from Brewfile (brew bundle)"
  brew bundle --file="$SCRIPT_DIR/Brewfile" || warn "brew bundle had failures; continuing"
fi

# ---------------------------------------------------------------------------
# 2. oh-my-zsh + custom plugins
# ---------------------------------------------------------------------------
if [ "$DO_OMZ" -eq 1 ]; then
  ZSH_DIR="$HOME/.oh-my-zsh"
  ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
  if [ ! -d "$ZSH_DIR" ]; then
    log "Installing oh-my-zsh"
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
  clone_plugin() {
    local repo="$1" name="$2" dir="$ZSH_CUSTOM/plugins/$2"
    if [ ! -d "$dir" ]; then
      log "Cloning zsh plugin: $name"
      git clone --depth=1 "$repo" "$dir"
    fi
  }
  clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting.git zsh-syntax-highlighting
  clone_plugin https://github.com/zsh-users/zsh-autosuggestions zsh-autosuggestions
fi

# ---------------------------------------------------------------------------
# 3. Shell + git dotfiles
# ---------------------------------------------------------------------------
log "Installing shell + git dotfiles"
install_file "$SCRIPT_DIR/.gitconfig"  "$HOME/.gitconfig"
install_file "$SCRIPT_DIR/.zshenv"     "$HOME/.zshenv"
install_file "$SCRIPT_DIR/.zshrc"      "$HOME/.zshrc"
install_file "$SCRIPT_DIR/.zshrc.work" "$HOME/.zshrc.work"
if [ ! -f "$HOME/.zshrc.local" ]; then
  log "Seeding ~/.zshrc.local from template (edit it for this machine)"
  cp "$SCRIPT_DIR/.zshrc.local.example" "$HOME/.zshrc.local"
fi

# ---------------------------------------------------------------------------
# 4. Editors (VS Code always; Cursor too)
# ---------------------------------------------------------------------------
if [ "$DO_EDITORS" -eq 1 ]; then
  log "Installing editor settings"
  install_file "$SCRIPT_DIR/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
  install_file "$SCRIPT_DIR/vscode/settings.json"    "$HOME/Library/Application Support/Code/User/settings.json"
  install_file "$SCRIPT_DIR/cursor/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"
  install_file "$SCRIPT_DIR/cursor/settings.json"    "$HOME/Library/Application Support/Cursor/User/settings.json"
fi

# ---------------------------------------------------------------------------
# 5. Warp terminal
# ---------------------------------------------------------------------------
if [ "$DO_WARP" -eq 1 ]; then
  log "Installing Warp settings"
  install_file "$SCRIPT_DIR/warp/settings.toml"    "$HOME/.warp/settings.toml"
  install_file "$SCRIPT_DIR/warp/keybindings.yaml" "$HOME/.warp/keybindings.yaml"
  mkdir -p "$HOME/.warp/tab_configs"
  for f in "$SCRIPT_DIR"/warp/tab_configs/*.toml; do
    [ -f "$f" ] && install_file "$f" "$HOME/.warp/tab_configs/$(basename "$f")"
  done
fi

# ---------------------------------------------------------------------------
# 6. Claude Code: settings, statusline, skills, plugins
# ---------------------------------------------------------------------------
if [ "$DO_CLAUDE" -eq 1 ]; then
  log "Installing Claude Code config"
  mkdir -p "$HOME/.claude"

  # Merge curated durable settings into ~/.claude/settings.json WITHOUT clobbering
  # the machine-local permissions list (which lives in the existing file / settings.local.json).
  python3 - "$SCRIPT_DIR/claude/settings.json" "$HOME/.claude/settings.json" <<'PY'
import json, os, sys
curated_path, dest_path = sys.argv[1], sys.argv[2]
curated = json.load(open(curated_path))
dest = {}
if os.path.exists(dest_path):
    try: dest = json.load(open(dest_path))
    except Exception: dest = {}
# Durable keys win; everything else in dest (e.g. permissions) is preserved.
dest.update(curated)
json.dump(dest, open(dest_path, "w"), indent=2)
open(dest_path, "a").write("\n")
print("  merged ->", dest_path)
PY

  # ccstatusline: install the binary so settings.json can point at a fast local
  # shim ($HOME/Library/pnpm/ccstatusline) instead of running `npx ...@latest`
  # on every render (which is slow/flaky and renders a blank status line).
  install_file "$SCRIPT_DIR/config/ccstatusline/settings.json" "$HOME/.config/ccstatusline/settings.json"
  if command -v pnpm >/dev/null 2>&1; then
    log "Installing ccstatusline (pnpm global)"
    pnpm add -g ccstatusline >/dev/null 2>&1 || warn "could not install ccstatusline"
  else
    warn "pnpm not found; status line will fall back to npx on first launch"
  fi

  # Personal skills (rsync-style copy; preserves your edits elsewhere)
  log "Installing Claude skills"
  mkdir -p "$HOME/.claude/skills"
  for d in "$SCRIPT_DIR"/claude/skills/*/; do
    name="$(basename "$d")"
    rm -rf "$HOME/.claude/skills/$name"
    cp -R "$d" "$HOME/.claude/skills/$name"
  done

  # Heavy git-backed skill: clone fresh rather than vendor 130MB+
  EXCAL="$HOME/.claude/skills/excalidraw-diagram"
  if [ ! -d "$EXCAL/.git" ]; then
    log "Cloning excalidraw-diagram skill"
    rm -rf "$EXCAL"
    git clone --depth=1 https://github.com/coleam00/excalidraw-diagram-skill.git "$EXCAL" \
      || warn "could not clone excalidraw-diagram skill (skipping)"
  fi

  # Plugins + marketplaces: install if the Claude CLI is available; otherwise
  # Claude reads enabledPlugins/extraKnownMarketplaces from settings.json on launch.
  if command -v claude >/dev/null 2>&1; then
    log "Adding Claude plugin marketplaces"
    claude plugin marketplace add dpearson2699/swift-ios-skills  >/dev/null 2>&1 || true
    claude plugin marketplace add warpdotdev/claude-code-warp     >/dev/null 2>&1 || true
    log "Installing Claude plugins"
    for p in \
      context7@claude-plugins-official \
      code-simplifier@claude-plugins-official \
      playwright@claude-plugins-official \
      rust-analyzer-lsp@claude-plugins-official \
      vercel@claude-plugins-official \
      all-ios-skills@swift-ios-skills \
      warp@claude-code-warp; do
      claude plugin install "$p" >/dev/null 2>&1 || warn "could not install $p"
    done
  else
    warn "claude CLI not found; plugins will auto-install from settings.json on first launch"
  fi
fi

# ---------------------------------------------------------------------------
# 7. Optional: daily backup agent (launchd)
# ---------------------------------------------------------------------------
# Resolve to yes/no. When AGENT=ask, prompt only if we have an interactive
# terminal; otherwise default to no so unattended installs never hang.
if [ "$AGENT" = "ask" ]; then
  if [ -t 0 ]; then
    printf '\n\033[1;34m==>\033[0m Set up a daily launchd backup agent (captures live config -> git push)? [y/N] '
    read -r reply
    case "$reply" in [Yy]*) AGENT=yes ;; *) AGENT=no ;; esac
  else
    AGENT=no
  fi
fi
if [ "$AGENT" = "yes" ]; then
  log "Installing daily backup agent"
  "$SCRIPT_DIR/sync.sh" --install-agent
fi

log "Done."
[ -d "$BACKUP_DIR" ] && log "Backups of replaced files: $BACKUP_DIR"
echo
echo "Next steps:"
echo "  - Restart your terminal (or: exec zsh) to load the new shell config"
echo "  - Edit ~/.zshrc.local for machine-specific paths/aliases"
echo "  - Launch Claude Code to finish any pending plugin installs"
[ "$AGENT" = "no" ] && echo "  - Enable daily backups anytime: ./sync.sh --install-agent"
