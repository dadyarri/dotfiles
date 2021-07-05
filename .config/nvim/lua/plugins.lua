-- Shortcuts
local cmd = vim.cmd

cmd 'packadd packer.nvim'

return require('packer').startup(function(use)
	-- Neovim APIs
	use 'nvim-lua/popup.nvim'
	use 'nvim-lua/plenary.nvim'

	use 'wbthomason/packer.nvim'  -- Package manager

	use 'kyazdani42/nvim-tree.lua' -- File tree
	use 'glepnir/galaxyline.nvim'  -- Status line

	use 'nvim-telescope/telescope.nvim'  -- Fuzzy-finder
	use 'nvim-telescope/telescope-media-files.nvim' -- Preview media in telescope

	use 'hrsh7th/nvim-compe'  -- LSP
	use 'neovim/nvim-lspconfig'  -- Configure LSP
	use 'glepnir/lspsaga.nvim'  -- LSP code actions

	use 'hrsh7th/vim-vsnip'  -- Snippets engine

	use 'terrortylor/nvim-comment'  -- Auto comment selected
	use 'windwp/nvim-autopairs'  -- Auto close paired brackets

	use {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'}  -- Improved code highlighting
	use 'onsails/lspkind-nvim'  -- Icons lsp completion items
	use 'kosayoda/nvim-lightbulb'  -- Lightbulb icon on line, where code actions available
	use 'mfussenegger/nvim-jdtls'  -- Refactor utils

	use 'kyazdani42/nvim-web-devicons'  -- Icons
	use 'wojciechkepka/vim-github-dark'  -- Dark theme
end)
