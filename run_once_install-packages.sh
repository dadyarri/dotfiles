#!/bin/bash

# Copy custome repositories to desired location
sudo cp repos/* /etc/yum.repos.d

# Install desired packages; Update system
sudo dnf copr enable atim/bottom -y
sudo dnf install bat brave-browser bottom code curl docker-ce docker-ce-cli docker-compose-plugin dotnet exa fd-find fzf git git-delta glow kio-gdrive neovim nodejs notion-app flameshot wezterm wl-clipboard zsh mosh -y
sudo dnf update -y

# Set zsh as default shell for current user
sudo chsh -s "$(which zsh)" "$USER"

# Install wezterm's terminfo
tempfile=$(mktemp) \
  && curl -o "$tempfile" https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo \
  && tic -x -o ~/.terminfo "$tempfile" \
  && rm "$tempfile"

# Install choosenim to manage nim versions
curl https://nim-lang.org/choosenim/init.sh -sSf | sh

# Install stable version of nim
choosenim stable

# Configure NPM to install global packages to custom directory
npm config set prefix=~/.npm/packages

# Install LSPs
nimble install nimlsp
npm i -g bash-language-server vscode-langservers-extracted pyright typescript typescript-language-server
dotnet tool install --global csharp-ls

# Ask user to reboot system
echo "Now you can reboot your system. Do it now? [y/n]"
read -r ans

if [[ "$ans" == 'y' ]]; then
    reboot
fi

