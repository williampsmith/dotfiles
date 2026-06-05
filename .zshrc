# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme. See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Plugins. Standard plugins live in $ZSH/plugins/, custom in $ZSH_CUSTOM/plugins/.
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  z
  sudo
  web-search
  copypath
  copyfile
  dirhistory
)

source $ZSH/oh-my-zsh.sh

# ---------------------------------------------------------------------------
# Completion
# ---------------------------------------------------------------------------
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
zstyle ':completion:*' rehash true

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
# See backtraces for panics and anyhow errors
export RUST_BACKTRACE=1

# Toolchains: rustup (homebrew), cargo bin
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
export PATH="${CARGO_HOME:-$HOME/.cargo}/bin:$PATH"

# Native build deps
export OPENSSL_DIR="/opt/homebrew/opt/openssl@3"
export CPATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include:$CPATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# uv / pipx shims (managed by the standalone installer)
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
alias python="python3"
alias pip="pip3"
alias rlint="cargo fmt && cargo xclippy"
alias rtest="cargo nextest run"

# Launch Claude Code against a separate personal profile (~/.claude-personal),
# stripping any work API/Bedrock/Vertex env so it can't leak into the account.
claude-personal() {
  env \
    -u ANTHROPIC_API_KEY -u ANTHROPIC_AUTH_TOKEN -u ANTHROPIC_BASE_URL \
    -u ANTHROPIC_MODEL -u ANTHROPIC_DEFAULT_SONNET_MODEL \
    -u ANTHROPIC_DEFAULT_OPUS_MODEL -u ANTHROPIC_DEFAULT_HAIKU_MODEL \
    -u CLAUDE_CODE_OAUTH_TOKEN -u CLAUDE_CODE_USE_BEDROCK \
    -u CLAUDE_CODE_USE_VERTEX -u CLAUDE_CODE_USE_FOUNDRY \
    CLAUDE_CONFIG_DIR="$HOME/.claude-personal" \
    claude "$@"
}
alias pcld='claude-personal'

# ---------------------------------------------------------------------------
# Maintenance helpers (tracked in dotfiles repo)
#   ~/.zshrc.cleanup -> `dev-clean` disk-reclaim function
# ---------------------------------------------------------------------------
[ -f "$HOME/.zshrc.cleanup" ] && source "$HOME/.zshrc.cleanup"

# ---------------------------------------------------------------------------
# Machine- and work-specific config (kept out of the portable core)
#   ~/.zshrc.work  -> work toolchains (tracked in dotfiles repo)
#   ~/.zshrc.local -> per-machine paths & aliases (NOT tracked; see .example)
# ---------------------------------------------------------------------------
[ -f "$HOME/.zshrc.work" ] && source "$HOME/.zshrc.work"
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
