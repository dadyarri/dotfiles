local Terminal = require('toggleterm.terminal').Terminal
local lazygit = Terminal:new({
	cmd = "lazygit",
	hidden = true,
	on_open = function(term)
		vim.cmd("startinsert!")
		vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
	end,
})
local vimp = require('vimp')

vimp.nnoremap('<Leader>g', function ()
	lazygit:toggle()
end)

