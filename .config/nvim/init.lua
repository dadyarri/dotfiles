local vimp = require('vimp')

-- Import modules
require('config.settings')

require('config.plugins')
require('config.keys')

require('config.theme')
require('config.nv-lualine')

-- Configure plugins
require('config.nv-compe')
require('config.nv-comment')
require('config.nv-autopairs')
require('config.nv-treesitter')
require('config.nv-telescope.keys')
require('config.nv-tree')
require('config.nv-bufferline')
require('config.nv-gitsigns')
require('config.nv-rooter')

-- Enable language servers
require('lsp.lua-ls')
require('lsp.python-ls')


vimp.nnoremap('<leader>r', function()
  vimp.unmap_all()
  require("config.utils").unload_lua_namespace('config')
  vim.cmd('silent wa')
  dofile(vim.fn.stdpath('config') .. '/init.lua')
  print("Reloaded vimrc!")
end)
