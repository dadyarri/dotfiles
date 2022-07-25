local wezterm = require 'wezterm';

return {
  font = wezterm.font("JetBrainsMono Nerd Font Mono"),
  font_size = 14,
  color_scheme = "OneHalfDark",
  initial_rows = 20,
  initial_cols = 100,
  default_cursor_style = "SteadyBar",
  term = "wezterm",
  warn_about_missing_glyphs = false,
}
