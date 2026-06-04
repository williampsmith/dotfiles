# dotfiles

My macOS setup, reproducible on a fresh machine with one command.

## Install

```sh
git clone https://github.com/<you>/dotfiles.git ~/dev/git/dotfiles
cd ~/dev/git/dotfiles && ./install.sh
```

`install.sh` is idempotent — re-run it any time to pick up updates. Anything it
overwrites is backed up to `~/.dotfiles-backup/<timestamp>/` first.

```
./install.sh                # everything
./install.sh --dotfiles-only # only shell/git dotfiles (no brew/omz/editors/warp/claude/agent)
./install.sh --no-brew      # skip Homebrew + brew bundle
./install.sh --no-claude    # skip Claude Code config/skills/plugins
./install.sh --no-warp      # skip Warp settings
./install.sh --no-editors   # skip VS Code / Cursor settings
```

## What it manages

| Area | Files | Notes |
|------|-------|-------|
| **Homebrew** | `Brewfile` | Formulae, casks, cargo crates, npm globals, VS Code extensions (`brew bundle`). Regenerate with `brew bundle dump --force`. |
| **Shell** | `.zshrc`, `.zshenv`, `.zshrc.work` | oh-my-zsh + plugins (`z`, `sudo`, autosuggestions, syntax-highlighting, …), completion tuning, toolchain PATHs. |
| **Git** | `.gitconfig` | aliases, `delta` pager, rerere, credential manager. |
| **Claude Code** | `claude/settings.json`, `claude/skills/` | Curated global settings (model, statusline, plugins, marketplaces, voice, hooks) + 18 personal skills. `excalidraw-diagram` is cloned fresh by the installer. |
| **ccstatusline** | `config/ccstatusline/settings.json` | Status-line layout. |
| **Warp** | `warp/settings.toml`, `warp/keybindings.yaml`, `warp/tab_configs/` | Theme (`solarized_dark`), font, input mode, hotkeys, tab configs. |
| **Editors** | `vscode/`, `cursor/` | settings + keybindings. |

## Backing up changes (the reverse direction)

`install.sh` pushes the repo onto a machine. `sync.sh` does the opposite — it
**captures the machine's live config back into the repo** and commits/pushes it.

```sh
./sync.sh              # capture + commit + push to GitHub (the daily backup)
./sync.sh --stage-only # capture + git add only, review before committing
./sync.sh --no-push    # capture + commit locally, don't push
```

Because the config is split *locally* (work/machine bits live in their own
sourced/gitignored files), capture is a plain mirror — no manual curation. The
one exception is `claude/settings.json`: it's copied minus the volatile
`permissions` key (Claude manages that itself) and minus the superpowers plugin.

### Automated daily backup (launchd)

```sh
./sync.sh --install-agent     # schedule it
./sync.sh --uninstall-agent   # remove it
```

This installs a **LaunchAgent** (`~/Library/LaunchAgents/com.williampsmith.dotfiles-sync.plist`)
that runs `sync.sh --auto` at 12:00 daily. launchd is the right tool for a
laptop that isn't always awake: if the Mac was asleep or off at the scheduled
time, macOS runs the job **once on the next wake** — unlike `cron`, which simply
skips missed runs. Logs go to `~/Library/Logs/dotfiles-sync.log`.

**One requirement for unattended push:** the GitHub SSH key must be usable
without an interactive passphrase prompt. Add it to the keychain once:

```sh
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

(and `UseKeychain yes` + `AddKeysToAgent yes` in `~/.ssh/config`). If push ever
fails, the commit is still saved locally and the next run retries.

## Machine- vs work- vs core config

`.zshrc` loads three tiers, in order:

1. **Core** — `.zshrc` itself. Portable, general dev (rust, node/pnpm, python).
2. **Work** — `~/.zshrc.work` (tracked). Blockchain/Rialo toolchains: Solana,
   WASI SDK, rialoman.
3. **Local** — `~/.zshrc.local` (**gitignored**). Per-machine paths and aliases.
   The installer seeds it from `.zshrc.local.example`; edit it for the box.

## Claude Code notes

- Global, shareable settings live in `claude/settings.json`. The installer
  **merges** these into `~/.claude/settings.json`, preserving the machine-local
  `permissions` allow-list (which Claude grows automatically and belongs in
  `~/.claude/settings.local.json`, not in this repo).
- Plugins/marketplaces install via the `claude` CLI if present; otherwise Claude
  auto-installs them from `enabledPlugins` / `extraKnownMarketplaces` on launch.
- The `superpowers` plugin is intentionally **not** tracked or enabled.

## What is intentionally NOT tracked

`~/.claude.json` and session/history data, secrets, the heavy `excalidraw`
skill payload (re-cloned), the `superpowers` plugin, and `~/.zshrc.local`.
