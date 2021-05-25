-- Shortcuts
local cmd = vim.cmd

cmd 'packadd paq-nvim'

local paq = require('paq-nvim').paq

paq {'savq/paq-nvim'} -- Manage plugins
paq {'kyazdani42/nvim-tree.lua'} -- File tree
paq {'folke/which-key.nvim'} -- Helper, showing available keybindings
paq {'neovim/nvim-lspconfig'} -- Configure lsp
paq {'hrsh7th/nvim-compe'} -- LSP
paq {'hrsh7th/vim-vsnip'} -- Snippets
paq {'terrortylor/nvim-comment'} -- Auto comment selected
paq {'windwp/nvim-autopairs'} -- Auto close paired brackets
