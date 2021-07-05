local map = vim.api.nvim_set_keymap
local noresil = {noremap=true, silent=true}

map('n', '<leader>ff', ':Telescope find_files<CR>', noresil)
map('n', '<leader>fg', ':Telescope live_grep<CR>', noresil)
map('n', '<leader>fb', ':Telescope buffers<CR>', noresil)
map('n', '<leader>fh', ':Telescope help_tags<CR>', noresil)

