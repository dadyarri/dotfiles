require('nvim-autopairs').setup()

vim.g.completion_confirm_key = ""

local npairs = require('nvim-autopairs')
local map = vim.api.nvim_set_keymap


_G.MUtils= {}
MUtils.completion_confirm=function()
  if vim.fn.pumvisible() ~= 0  then
    if vim.fn.complete_info()["selected"] ~= -1 then
      return vim.fn["compe#confirm"](npairs.esc("<cr>"))
    else
      return npairs.esc("<cr>")
    end
  else
    return npairs.autopairs_cr()
  end
end

map('i' , '<CR>','v:lua.MUtils.completion_confirm()', {expr = true , noremap = true})

