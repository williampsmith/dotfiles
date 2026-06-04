#!/usr/bin/env bash
#
# Claude Code SessionStart hook: warn (visibly, to the user) when a session
# starts inside a repo owned by $WORK_ORG. No-ops everywhere else.
#
# $WORK_ORG is your work GitHub org slug, exported from the shell (see
# ~/.zshrc.work). The hook inherits it from the environment Claude was
# launched in. Detection = the owner segment of the `origin` remote URL.
set -euo pipefail

# Nothing to compare against → stay silent.
[ -n "${WORK_ORG:-}" ] || exit 0

url="$(git config --get remote.origin.url 2>/dev/null || true)"
[ -n "$url" ] || exit 0

# Extract the owner (org) from any of:
#   git@host:OWNER/repo.git | https://host/OWNER/repo.git | ssh://git@host/OWNER/repo.git
owner="$(printf '%s' "$url" | sed -E 's#^[a-z]+://##; s#^git@##; s#^[^/:]+[:/]##; s#/.*$##')"
repo="$(basename "$url" .git)"

# Case-insensitive compare (GitHub org slugs are case-insensitive).
lc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
if [ "$(lc "$owner")" = "$(lc "$WORK_ORG")" ]; then
  # owner/repo are GitHub names (no quotes/backslashes) → safe to inline in JSON.
  printf '{"systemMessage":"⚠️  WORK REPO (%s/%s) — follow work IP and security policy. For personal projects, use a personal profile (pcld)."}\n' "$owner" "$repo"
fi
exit 0
