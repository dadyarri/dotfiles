-- Shortcuts
local cmd = vim.cmd

cmd 'packadd paq-nvim'

local paq = require('paq-nvim').paq

paq {'savq/paq-nvim'} -- Manage plugins
paq {'kyazdani42/nvim-tree.lua'} -- File tree
paq {'folke/which-key.nvim'} -- Helper, showing available keybindings