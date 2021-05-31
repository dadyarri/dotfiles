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
paq {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'} -- Improved code highlighting
paq {'kyazdani42/nvim-web-devicons'} -- Icons
paq {'glepnir/galaxyline.nvim'} -- Status line
paq {'nvim-lua/popup.nvim'}
paq {'nvim-lua/plenary.nvim'}
paq {'nvim-telescope/telescope.nvim'}
paq {'nvim-telescope/telescope-media-files.nvim'}
paq {'glepnir/lspsaga.nvim'}
paq {'onsails/lspkind-nvim'}
paq {'kosayoda/nvim-lightbulb'}
paq {'mfussenegger/nvim-jdtls'}
paq {'mfussenegger/nvim-dap'}
paq {'wojciechkepka/vim-github-dark'}
paq {'matbme/JABS.nvim'}

