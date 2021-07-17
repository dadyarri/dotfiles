require('toggleterm').setup({
	open_mapping = [[<c-\>]],
	hide_numbers = true,
	direction = 'float',
	close_on_exit = true,
	float_opts = {
		border = 'curved',
	}
})
require('config.nv-toggleterm.terminals')

