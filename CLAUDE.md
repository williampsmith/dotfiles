# dotfiles

> Project memory for Claude Code. Loaded every session — keep concise and current.

## Overview
Personal macOS dotfiles. The goal is to reproduce a full machine setup on a fresh
box with one command (`install.sh`) and to keep that setup backed up automatically
(`sync.sh` + a launchd agent). It manages shell/git config, Homebrew packages,
Claude Code config + skills, Warp terminal, ccstatusline, and editor settings.

## Architecture
Two directions, plus a three-tier shell split:
- **Forward — `install.sh`** (repo → machine): idempotent. Installs Homebrew + `brew bundle`,
  oh-my-zsh + plugins, shell/git dotfiles, editor/Warp/ccstatusline config, and Claude
  settings/skills/plugins. Backs up anything it overwrites to `~/.dotfiles-backup/<ts>/`.
  Merges `claude/settings.json` into `~/.claude/settings.json` without clobbering the
  machine-local `permissions` list. Ends with an opt-in prompt for the backup agent.
- **Reverse — `sync.sh`** (machine → repo): captures live config back into the repo and
  commits/pushes. Most files are pure mirrors; the one transform is `claude/settings.json`
  (copied minus the volatile `permissions` key and minus the superpowers plugin).
  `--install-agent` installs a launchd worker that runs `sync.sh --auto` daily.
- **Shell tiers:** `.zshrc` (portable core) sources `~/.zshrc.work` (tracked work toolchains)
  then `~/.zshrc.local` (gitignored, per-machine; seeded from `.zshrc.local.example`).

Two Claude dirs with distinct roles: **`claude/`** (no dot) is the payload distributed to
`~/.claude`; **`.claude/`** (dot) is Claude Code config for working *in this repo*.

## Key Directories & Entry Points
- `install.sh` — one-command setup (forward). Primary entry point.
- `sync.sh` — capture + backup (reverse); also manages the launchd agent.
- `Brewfile` — formulae, casks, cargo crates, npm globals, VS Code extensions.
- `.zshrc`, `.zshrc.work`, `.zshrc.cleanup`, `.zshrc.local.example`, `.zshenv`, `.gitconfig` — shell + git.
- `.zshrc.cleanup` — defines `dev-clean` (disk reclaim: cargo/JS build output, Docker, package caches; risky categories opt-in).
- `claude/settings.json`, `claude/skills/` — Claude payload (18 skills; excalidraw re-cloned).
- `warp/`, `config/ccstatusline/`, `vscode/`, `cursor/` — app config mirrors.

## Commands
> This repo has no build/test/run; "validation" means scripts parse and configs are valid JSON.

- Install:   `./install.sh`            (mutates `$HOME`; backs up first)
- Back up:   `./sync.sh`               (capture live config → commit → push)
- Validate:  `bash -n install.sh sync.sh`   (shell syntax) + JSON validity (see below)
- Dry-run:   `./sync.sh --stage-only`   (capture + stage, no commit)
- Build / Test / Lint / Format / Run: none configured

JSON validity check:
`for f in claude/settings.json config/ccstatusline/settings.json vscode/*.json cursor/*.json; do python3 -m json.tool "$f" >/dev/null || echo "BAD: $f"; done`

## Conventions
- Scripts are **idempotent** and safe to re-run; use `set -euo pipefail`.
- Overwrites go through `install_file` (backs up the old file first); never clobber blindly.
- **Mirror vs curated:** most files copy verbatim live↔repo. Curated exceptions are
  documented (claude `permissions` stay machine-local; superpowers excluded).
- Machine-specific values belong in gitignored `~/.zshrc.local`, work toolchains in
  `~/.zshrc.work` — never hardcode them into the portable core `.zshrc`.
- `$HOME`-relative paths over hardcoded `/Users/...` where a command is shell-expanded.

## Gotchas
- launchd runs with a minimal PATH — `sync.sh` and the agent plist prepend `~/.cargo/bin`
  so `brew bundle dump` doesn't silently drop cargo crates.
- Unattended `git push` needs the SSH key in the keychain
  (`ssh-add --apple-use-keychain ~/.ssh/<key>`), else the daily backup commits locally only.
- The status line points at `$HOME/Library/pnpm/ccstatusline` (installed binary), not
  `npx ...@latest`, which was too slow per-render and rendered blank.
- `claude/settings.json` is curated — do **not** paste machine permissions or superpowers in.

## Agentic Workflow
This repo is set up for spec-driven agentic engineering:
- Plan with `/feature`, `/bug`, or `/chore` — they write a detailed plan to `specs/*.md`.
- Execute a plan with `/implement`.
- Prime a fresh session with `/prime`.
- Subagents live in `.claude/agents/` (see `code-reviewer`).
