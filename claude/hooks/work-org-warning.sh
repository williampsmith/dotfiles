#!/usr/bin/env bash
#
# Claude Code SessionStart hook: LOUDLY warn (visibly, to the user) when a
# session starts inside a git repo that is NOT owned by $WORK_ORG — i.e. you're
# about to use your default/work Claude profile on a non-work project, where you
# probably meant `pcld` (personal). Silent inside $WORK_ORG repos.
#
# $WORK_ORG is your work GitHub org slug, exported from the shell (see
# ~/.zshrc.work). Detection = the owner segment of the `origin` remote URL.
set -euo pipefail

# No org configured → nothing to compare against.
[ -n "${WORK_ORG:-}" ] || exit 0

# Only act inside a git work tree (don't nag in scratch/home dirs).
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

url="$(git config --get remote.origin.url 2>/dev/null || true)"
if [ -n "$url" ]; then
  # Extract owner from git@host:OWNER/repo.git | https://host/OWNER/repo.git | ssh://...
  owner="$(printf '%s' "$url" | sed -E 's#^[a-z]+://##; s#^git@##; s#^[^/:]+[:/]##; s#/.*$##')"
  repo="$(basename "$url" .git)"
else
  owner=""
  repo="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo .)")"
fi

# Case-insensitive compare (GitHub org slugs are case-insensitive).
lc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# Warn when the repo is NOT the work org's.
if [ "$(lc "$owner")" != "$(lc "$WORK_ORG")" ]; then
  loc="$repo"
  [ -n "$owner" ] && loc="$owner/$repo"
  # loc and WORK_ORG are git/org names (no quotes/backslashes) → safe inline.
  printf '{"systemMessage":"🚨🚨🚨 NON-WORK REPO (%s) 🚨🚨🚨 — THIS IS NOT A %s REPO, BUT YOU ARE IN YOUR WORK CLAUDE PROFILE. IF THIS IS A PERSONAL PROJECT, EXIT AND USE claude-personal (alias: pcld) INSTEAD. ⚠️⚠️⚠️"}\n' "$loc" "$WORK_ORG"
fi
exit 0
