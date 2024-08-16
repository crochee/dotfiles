local wezterm = require("wezterm")
local platform = require("utils.platform")

return {
	-- color scheme
	color_scheme = "Catppuccin Macchiato (Gogh)",
	font_size = platform().is_mac and 20 or 18,
	line_height = 1.2,
	font = wezterm.font("FantasqueSansM Nerd Font Mono", { weight = "Bold", italic = true }),
}
