-----------------------------------------------------------
-- File manager configuration file
-----------------------------------------------------------

-- Plugin: nvim-tree
-- url: https://github.com/kyazdani42/nvim-tree.lua

-- Keybindings are defined in `core/keymaps.lua`:
-- https://github.com/kyazdani42/nvim-tree.lua#keybindings

-- Note: options under the g: command should be set BEFORE running the
-- setup function: https://github.com/kyazdani42/nvim-tree.lua#setup
-- Default options ARE NOT included.
-- See: `:help NvimTree`


-- Global options
local g = vim.g

g.nvim_tree_width_allow_resize  = 1

local status_ok, nvim_tree = pcall(require, 'nvim-tree')
if not status_ok then
  return
end

-- Call setup:
--- Each of these are documented in `:help nvim-tree.OPTION_NAME`
nvim_tree.setup {
  open_on_setup = true,
  --open_on_setup_file = true,
  open_on_tab = true,
  update_cwd = true,
  view = { width = 32 },
  renderer = {
    icons = {
      glyphs = {
        default = "",
      },
      show = {
        git = true,
        folder = true,
        file = true,
      },
    },
    indent_markers = {
      enable = false,
      icons = {
        corner = "└ ",
        edge = "│ ",
        none = "  ",
      },
    },
    highlight_opened_files = "icon",
    highlight_git = true,
  },
  actions = {
    change_dir = { enable = false },
  },
  update_focused_file = {
    enable = true,
    update_cwd = true,
  },
  filters = {
    dotfiles = true,
    custom = { 'node_modules', '.cache', '.bin' },
  },
  respect_buf_cwd = true,
}

