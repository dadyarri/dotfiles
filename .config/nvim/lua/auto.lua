local cmd = vim.api.nvim_command

-- Set path, given in argv as vim's pwd
cmd('autocmd VimEnter * cd %:h')
