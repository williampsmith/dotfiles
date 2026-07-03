. "$HOME/.cargo/env"

# athema control-plane operator creds (file is 0600, never committed)
[ -f "$HOME/.config/athema/secrets.env" ] && source "$HOME/.config/athema/secrets.env"
