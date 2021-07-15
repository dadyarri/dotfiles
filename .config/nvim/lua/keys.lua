local map = vim.api.nvim_set_keymap
local noresil = {noremap=true, silent=true}

map('n', '<Space>', '<NOP>', noresil) -- Disable space

vim.g.mapleader = ',' -- Set leader key to comma

map('n', '<Leader>h', ':set hlsearch!<CR>', noresil) -- Switch highlighting in search mode
map('n', '<Leader>t', ':NvimTreeToggle<CR>', noresil) -- Switch files tree
map('n', '<Leader>s', ':luafile ~/.config/nvim/init.lua<CR>', noresil) -- Switch files tree

-- Better window movement
map('n', '<C-h>', '<C-w>h', noresil) -- To the LEFT
map('n', '<C-j>', '<C-w>j', noresil) -- To the DOWN
map('n', '<C-k>', '<C-w>k', noresil) -- To the UP
map('n', '<C-l>', '<C-w>l', noresil) -- To the RIGHT

-- Better indenting
map('v', '<', '<gv', noresil) -- Indent selected to the LEFT
map('v', '>', '>gv', noresil) -- Indent selected to the RIGHT

-- Switch buffers by TAB
map('n', '<TAB>', ':bnext<CR>', noresil)
map('n', '<S-TAB>', ':bprev<CR>', noresil)

-- Move selected block of text in visual mode
map('v', 'K', ':move \'<-2<CR>gv-gv\'', noresil) -- Move selected to the UP
map('v', 'J', ':move \'>+1<CR>gv-gv\'', noresil) -- Move selected to the DOWN

-- Move line
map('n', '<M-k>', 'ddkP', noresil)  -- Move to the UP
map('n', '<M-j>', 'ddp', noresil)  -- Move to the DOWN

map('i', 'jj', '<ESC>', noresil) -- Press ESC on fast pressing jj in insert mode

-- Search forward by '<Space>' and backward by '<S-Space>'
map('n', '<Space>', '/', noresil)
map('n', '<C-Space>', '?', noresil)

-- Add new line and exit to normal mode
map('n', '<S-Enter>', 'O<Esc>', noresil)
map('n', '<CR>', 'o<Esc>', noresil)

-- Manage buffers
map('n', '<Leader>c', ':bd<CR>', noresil)
map('n', '<Leader>z', ':BufferLineCyclePrev<CR>', noresil)
map('n', '<Leader>x', ':BufferLineCycleNext<CR>', noresil)

