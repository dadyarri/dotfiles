#!/bin/bash

sudo cp repos/* /etc/yum.repos.d

sudo dnf install bat brave-browser code docker-ce docker-ce-cli docker-compose-plugin dotnet exa fd-find fzf git git-delta glow kio-gdrive neovim nodejs notion-app spectacle wezterm xclip zsh -y
