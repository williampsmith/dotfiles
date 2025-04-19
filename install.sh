#! /bin/bash

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "This script, when executed, will copy all dotfiles contained in this repo to the"
    echo "appropriate locations in the user's home directory. Rather than using symlinks,"
    echo "the files are copied over directly. This script also installs oh-my-zsh and"
    echo "oh-my-zsh plugins."
    echo ""
    echo "Usage: $0 [-A]"
    echo "  -A: Install additional files (cursor keybindings and settings)"
    echo "  -h: Display this help message"
    exit 0
fi

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# install .gitconfig
cp $SCRIPT_DIR/.gitconfig $HOME/

# install oh-my-zsh and plugins
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# install .zshrc
cp $SCRIPT_DIR/.zshrc $HOME/

# install .zshenv
cp $SCRIPT_DIR/.zshenv $HOME/

# install VSCode keybindings and settings
cp $SCRIPT_DIR/vscode/keybindings.json $HOME/Library/Application\ Support/Code/User/
cp $SCRIPT_DIR/vscode/settings.json $HOME/Library/Application\ Support/Code/User/

# install cursor keybindings and settings if -A flag is provided
if [[ "$1" == "-A" ]]; then
    cp $SCRIPT_DIR/cursor/keybindings.json $HOME/Library/Application\ Support/Cursor/User/
    cp $SCRIPT_DIR/cursor/settings.json $HOME/Library/Application\ Support/Cursor/User/
fi

echo "Installation complete!"
echo "Please restart your editor and terminal to apply the changes."