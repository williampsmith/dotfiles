# Prime
> Execute the following sections to understand the codebase, then summarize your understanding.

## Run
git ls-files

## Read
README.md
CLAUDE.md

## Report
Summarize, in a few tight bullets:
- What this dotfiles repo is and its high-level architecture (forward `install.sh` /
  reverse `sync.sh`; the three-tier zsh split; the mirror-vs-curated distinction).
- The key files and entry points.
- How to install (`./install.sh`), back up (`./sync.sh`), and validate
  (`bash -n install.sh sync.sh` + JSON validity) — this repo has no build/test/run.
