#!/usr/bin/env bash
#
# Capture this machine's live config back INTO the repo (the reverse of
# install.sh), then optionally commit & push. This is the daily-backup path.
#
# Almost everything is a pure mirror (live -> repo). The only transform is
# Claude's settings.json, which is copied minus the volatile `permissions`
# key (Claude grows that automatically) and minus the superpowers plugin.
#
# Usage:
#   ./sync.sh                 Capture + commit + push   (default; "back up")
#   ./sync.sh --stage-only    Capture + `git add`, no commit (review by hand)
#   ./sync.sh --no-push       Capture + commit locally, don't push
#   ./sync.sh --auto          Quiet capture + commit + push (used by launchd)
#   ./sync.sh --install-agent Install the daily launchd backup agent
#   ./sync.sh --uninstall-agent
#   -h | --help

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MODE="commit-push"   # commit-push | stage-only | no-push
QUIET=0
AGENT_LABEL="com.williampsmith.dotfiles-sync"
PLIST="$HOME/Library/LaunchAgents/$AGENT_LABEL.plist"
LOG="$HOME/Library/Logs/dotfiles-sync.log"

case "${1:-}" in
  --stage-only) MODE="stage-only" ;;
  --no-push)    MODE="no-push" ;;
  --auto)       MODE="commit-push"; QUIET=1 ;;
  --install-agent)   install_agent=1 ;;
  --uninstall-agent) uninstall_agent=1 ;;
  -h|--help) sed -n '3,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  "") ;;
  *) echo "Unknown option: $1 (see --help)"; exit 1 ;;
esac

log()  { [ "$QUIET" -eq 1 ] || printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  ! \033[0m%s\n' "$*" >&2; }

# --- launchd agent management ----------------------------------------------
if [ "${install_agent:-0}" -eq 1 ]; then
  mkdir -p "$(dirname "$PLIST")" "$(dirname "$LOG")"
  cat > "$PLIST" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$AGENT_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$SCRIPT_DIR/sync.sh</string>
    <string>--auto</string>
  </array>
  <!-- Runs daily at 12:00. If the Mac was asleep/off then, launchd runs it
       once on the next wake (this is why launchd beats cron for laptops). -->
  <key>StartCalendarInterval</key>
  <dict><key>Hour</key><integer>12</integer><key>Minute</key><integer>0</integer></dict>
  <key>EnvironmentVariables</key>
  <dict><key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string></dict>
  <key>StandardOutPath</key><string>$LOG</string>
  <key>StandardErrorPath</key><string>$LOG</string>
  <key>RunAtLoad</key><false/>
</dict>
</plist>
PLISTEOF
  launchctl unload "$PLIST" 2>/dev/null || true
  launchctl load "$PLIST"
  log "Installed daily backup agent: $AGENT_LABEL"
  log "  schedule: 12:00 daily (catches up on next wake if asleep)"
  log "  logs:     $LOG"
  log "  run now:  launchctl start $AGENT_LABEL"
  exit 0
fi
if [ "${uninstall_agent:-0}" -eq 1 ]; then
  launchctl unload "$PLIST" 2>/dev/null || true
  rm -f "$PLIST"
  log "Removed backup agent: $AGENT_LABEL"
  exit 0
fi

# --- helpers ----------------------------------------------------------------
pull() {  # pull <home-path> <repo-path>
  local src="$1" dest="$2"
  if [ ! -e "$src" ]; then return 0; fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
}

VSCODE="$HOME/Library/Application Support/Code/User"
CURSOR="$HOME/Library/Application Support/Cursor/User"

log "Capturing live config into repo"

# Shell + git (pure mirrors; the split lives in the live files themselves)
pull "$HOME/.zshrc"      ".zshrc"
pull "$HOME/.zshrc.work" ".zshrc.work"
pull "$HOME/.zshenv"     ".zshenv"
pull "$HOME/.gitconfig"  ".gitconfig"

# Editors
pull "$VSCODE/settings.json"    "vscode/settings.json"
pull "$VSCODE/keybindings.json" "vscode/keybindings.json"
pull "$CURSOR/settings.json"    "cursor/settings.json"
pull "$CURSOR/keybindings.json" "cursor/keybindings.json"

# Warp
pull "$HOME/.warp/settings.toml"    "warp/settings.toml"
pull "$HOME/.warp/keybindings.yaml" "warp/keybindings.yaml"
mkdir -p warp/tab_configs
for f in "$HOME"/.warp/tab_configs/*.toml; do
  [ -f "$f" ] && pull "$f" "warp/tab_configs/$(basename "$f")"
done

# ccstatusline
pull "$HOME/.config/ccstatusline/settings.json" "config/ccstatusline/settings.json"

# Claude personal skills (mirror with deletions; excalidraw is re-cloned, never vendored)
if [ -d "$HOME/.claude/skills" ]; then
  rm -rf claude/skills
  mkdir -p claude/skills
  for d in "$HOME"/.claude/skills/*/; do
    name="$(basename "$d")"
    [ "$name" = "excalidraw-diagram" ] && continue
    cp -R "$d" "claude/skills/$name"
    rm -rf "claude/skills/$name/.git"
  done
fi

# Claude settings: copy minus `permissions` and minus superpowers plugin
if [ -f "$HOME/.claude/settings.json" ]; then
  python3 - "$HOME/.claude/settings.json" "claude/settings.json" <<'PY'
import json, sys
live = json.load(open(sys.argv[1]))
live.pop("permissions", None)          # volatile; Claude manages it locally
ep = live.get("enabledPlugins")
if isinstance(ep, dict):
    live["enabledPlugins"] = {k: v for k, v in ep.items() if not k.startswith("superpowers@")}
json.dump(live, open(sys.argv[2], "w"), indent=2)
open(sys.argv[2], "a").write("\n")
PY
fi

# Brewfile: formulae, casks, cargo, npm, vscode extensions
if command -v brew >/dev/null 2>&1; then
  log "Regenerating Brewfile"
  brew bundle dump --file=Brewfile --force >/dev/null 2>&1 || warn "brew bundle dump failed"
fi

# --- commit / push ----------------------------------------------------------
git add -A
if git diff --cached --quiet; then
  log "No changes to back up."
  exit 0
fi

if [ "$MODE" = "stage-only" ]; then
  log "Staged changes (no commit):"
  git status --short
  exit 0
fi

STAMP="$(date '+%Y-%m-%d %H:%M')"
git -c user.name="William Smith" -c user.email="williamprincesmith@gmail.com" \
  commit -q -m "chore: sync dotfiles ($STAMP)" \
  -m "Automated capture of live config." || { warn "commit failed"; exit 1; }
log "Committed changes."

if [ "$MODE" = "no-push" ]; then
  log "Skipping push (--no-push)."
  exit 0
fi

if git push -q 2>>"${LOG:-/dev/stderr}"; then
  log "Pushed to origin."
else
  warn "Push failed (commit saved locally). If automated: ensure the SSH key is in the keychain (ssh-add --apple-use-keychain ~/.ssh/<key>)."
  exit 0
fi
