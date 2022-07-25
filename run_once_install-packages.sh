#!/bin/bash

# Copy custome repositories to desired location
sudo cp repos/* /etc/yum.repos.d

# Install desired packages; Update system
sudo dnf install bat brave-browser code curl docker-ce docker-ce-cli docker-compose-plugin dotnet exa fd-find fzf git git-delta glow kio-gdrive neovim nodejs notion-app spectacle wezterm xclip zsh -y
sudo dnf update -y

# Get latest version of afx (package manager for shell)
kernelName=$(uname -s)
machine=$(uname -m)
url="https://github.com/b4b4r07/afx/releases/latest/download/afx_${kernelName,,}_$machine.tar.gz"
file="afx.tar.gz"

curl -L "$url" -o $file

sudo tar xzf $file -C /usr/local/bin
rm -rf $file

# Set zsh as default shell for current user
sudo chsh -s "$(which zsh)" "$USER"

echo "Now you can reboot your system. Do it now? [y/n]"
read -r ans

if [[ "$ans" -eq 'y' ]]; then
    reboot
fi

