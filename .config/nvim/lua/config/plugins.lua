-- Shortcuts
local cmd = vim.cmd

cmd 'packadd packer.nvim'

return require('packer').startup(function(use)
	-- Neovim APIs
	use 'nvim-lua/popup.nvim'
	use 'nvim-lua/plenary.nvim'

	use 'wbthomason/packer.nvim'  -- Package manager

	use {
		'kyazdani42/nvim-tree.lua',
		commit = "fd7f60e242205ea9efc9649101c81a07d5f458bb",
	} -- File tree
	use 'hoob3rt/lualine.nvim'  -- Status line
	use 'akinsho/nvim-bufferline.lua' -- Buffers list

	use 'nvim-telescope/telescope.nvim'  -- Fuzzy-finder
	use 'nvim-telescope/telescope-media-files.nvim' -- Preview media in telescope
	use 'nvim-telescope/telescope-project.nvim'  -- Manage projects via telescope

	use 'nacro90/numb.nvim'  -- Easy go-to-line
	use 'ahmedkhalf/lsp-rooter.nvim'  -- Go to root of project when opening vim via LSP

	use 'hrsh7th/nvim-compe'  -- LSP
	use 'neovim/nvim-lspconfig'  -- Configure LSP
	use 'glepnir/lspsaga.nvim'  -- LSP code actions

	use 'hrsh7th/vim-vsnip'  -- Snippets engine

	use 'terrortylor/nvim-comment'  -- Auto comment selected
	use 'windwp/nvim-autopairs'  -- Auto close paired brackets

	use {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'}  -- Improved code highlighting

	use 'TimUntersberger/neogit'  -- Git manager
	use 'lewis6991/gitsigns.nvim'  -- Git signs in left bar

	use 'wakatime/vim-wakatime'  -- Wakatime (time tracker)

	use 'kyazdani42/nvim-web-devicons'  -- Icons
	use 'kosayoda/nvim-lightbulb'  -- Lightbulb icon on line, where code actions available
	use 'onsails/lspkind-nvim'  -- Icons lsp completion items
	use 'yashguptaz/calvera-dark.nvim'  -- Dark theme

	use 'svermeulen/vimpeccable'  -- Bind lua code to keys
	use 'akinsho/nvim-toggleterm.lua'  -- Persist and toggle multiline terminals
end)
