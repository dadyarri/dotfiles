-- Import modules
require('settings')
require('auto')

require('plugins')
require('keys')

require('theme')
require('nv-lualine')

-- Configure plugins
require('nv-compe')
require('nv-comment')
require('nv-autopairs')
require('nv-treesitter')
require('nv-telescope.keys')
require('nv-tree')
require('nv-bufferline')
require('nv-gitsigns')

-- Enable language servers
require('lsp.lua-ls')
require('lsp.python-ls')

